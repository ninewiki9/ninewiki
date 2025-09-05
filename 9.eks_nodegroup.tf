# EKS 노드 그룹 IAM 역할
resource "aws_iam_role" "eks_node_group" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# EKS 워커 노드 정책 연결
resource "aws_iam_role_policy_attachment" "eks_node_group_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "CNI" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# CloudWatch Agent 정책 연결
resource "aws_iam_role_policy_attachment" "eks_cw_agent_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# X-Ray Write Only Access 정책 연결
resource "aws_iam_role_policy_attachment" "eks_xray_write_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

# EKS 최적화 AMI 데이터 소스
data "aws_ami" "eks_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.28-v*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EKS 노드 그룹용 런치 템플릿
resource "aws_launch_template" "eks_node_group" {
  name_prefix            = "eks-node-group-"
  description            = "EKS Node Group Launch Template"
  update_default_version = true

  # 네트워크 인터페이스 설정
  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [aws_security_group.eks_worker_sg.id]
  }

  # EKS 최적화 AMI 사용
  image_id = data.aws_ami.eks_optimized.id

  # 인스턴스 타입 설정
  instance_type = "t3.medium"

  # 사용자 데이터 (EKS 부트스트랩: 런치 템플릿으로 만든 인스턴스를 eks 노드에 가입시킴)
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = aws_eks_cluster.eks_master.name
    bootstrap_extra_args = "--kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup=ninewiki-eks-node-group'"
  }))

  # 인스턴스 태그 설정
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node-group-instance"
      Project = "ninewiki"
      Environment = "production"
      Owner = "ninewiki-team"
      "kubernetes.io/cluster/${aws_eks_cluster.eks_master.name}" = "owned"
      "kubernetes.io/role/node" = "1"
    }
  }

  # 볼륨 태그 설정
  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "eks-node-group-volume"
      Project = "ninewiki"
      Environment = "production"
      Owner = "ninewiki-team"
      "kubernetes.io/cluster/${aws_eks_cluster.eks_master.name}" = "owned"
    }
  }

  # 네트워크 인터페이스 태그 설정
  tag_specifications {
    resource_type = "network-interface"
    tags = {
      Name = "eks-node-group-eni"
      Project = "ninewiki"
      Environment = "production"
      "kubernetes.io/cluster/${aws_eks_cluster.eks_master.name}" = "owned"
    }
  }

  # 런치 템플릿 자체 태그
  tags = {
    Name = "eks-node-group-lt"
    Project = "ninewiki"
    Environment = "production"
    Owner = "ninewiki-team"
    "kubernetes.io/cluster/${aws_eks_cluster.eks_master.name}" = "owned"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EKS 노드 그룹 생성
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_master.name
  node_group_name = "ninewiki-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn

  subnet_ids = [aws_subnet.pri-subnet-2a.id, aws_subnet.pri-subnet-2c.id]

  # 런치 템플릿 사용
  launch_template {
    id      = aws_launch_template.eks_node_group.id
    version = aws_launch_template.eks_node_group.latest_version
  }

  # IMDSv2 설정
  update_config {
    max_unavailable = 1
  }

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 3
  }

  tags = {
    Name        = "ninewiki-eks-worker-node"
    Project     = "ninewiki"
    Environment = "production"
    Owner       = "ninewiki-team"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_policy,
    aws_iam_role_policy_attachment.CNI,
    aws_iam_role_policy_attachment.ecr,
    aws_iam_role_policy_attachment.eks_cw_agent_policy,
    aws_iam_role_policy_attachment.eks_xray_write_policy,
    aws_security_group.eks_worker_sg,
    aws_launch_template.eks_node_group
  ]
}

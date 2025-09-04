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

# EKS 노드 그룹 생성
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_master.name
  node_group_name = "ninewiki-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn

  subnet_ids = [aws_subnet.pri-subnet-2a.id, aws_subnet.pri-subnet-2c.id]
  # 인스턴스 타입 설정
  instance_types = ["t3.medium"]

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
    aws_security_group.eks_worker_sg
  ]
}


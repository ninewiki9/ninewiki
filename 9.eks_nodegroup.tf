


# node group IAM role 생성
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

#  IAM role에 정책 부착
resource "aws_iam_role_policy_attachment" "eks_node_group_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"  # EKS 워커 노드가 EKS 클러스터와 통신할 수 있는 권한
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "CNI" {
  policy_arn ="arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"  # Amazon VPC CNI 플러그인이 ENI를 관리할 수 있는 권한
  role       = aws_iam_role.eks_node_group.name
}


resource "aws_iam_role_policy_attachment" "ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"  # ECR에서 이미지를 가져올 수 있는 읽기 권한
  role       = aws_iam_role.eks_node_group.name
}



#node group 생성 (단순화된 설정)
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
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }

  tags = {
    Name    = "ninewiki-eks-worker-node"
    Project = "ninewiki-test"
    Environment = "production"
    Owner = "ninewiki-team"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_policy,
    aws_iam_role_policy_attachment.CNI,
    aws_iam_role_policy_attachment.ecr
  ]
}









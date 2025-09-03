
# EKS 클러스터 IAM 역할
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}
resource "aws_iam_role_policy_attachment" "eks_vpc_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}



resource "aws_eks_cluster" "eks_master" {
  name     = "ninewiki-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = [aws_subnet.pri-subnet-2a.id, aws_subnet.pri-subnet-2c.id]
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }



  depends_on = [ # eks_cluster가 아래 표시된 정책이 우선되야함함
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_controller
  ]

  tags = {
    Name    = "ninewiki-eks-cluster"
    Project = "ninewiki"
  }
}

# === EKS Container Insights (Pod Identity + Observability Add-on) ===

# === EKS Pod Identity Agent add-on ===
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.eks_master.name
  addon_name   = "eks-pod-identity-agent"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  
  depends_on = [
    aws_eks_cluster.eks_master
  ]
}

# === IAM Role for CloudWatch Observability add-on ===
# Trusts EKS Pod Identity ("pods.eks.amazonaws.com")
resource "aws_iam_role" "cw_obs_sa_role" {
  name = "eks-${aws_eks_cluster.eks_master.name}-cw-observability-sa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "pods.eks.amazonaws.com" },
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

# Attach the managed policy required by CloudWatch Agent
resource "aws_iam_role_policy_attachment" "cw_agent_attach" {
  role       = aws_iam_role.cw_obs_sa_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# === Outputs ===
output "eks_addons" {
  value = {
    pod_identity_agent = aws_eks_addon.pod_identity_agent.addon_version
  }
}

output "cloudwatch_observability_role_arn" {
  value = aws_iam_role.cw_obs_sa_role.arn
}





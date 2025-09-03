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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" # EKS 워커 노드가 EKS 클러스터와 통신할 수 있는 권한
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "CNI" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" # Amazon VPC CNI 플러그인이 ENI를 관리할 수 있는 권한
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # ECR에서 이미지를 가져올 수 있는 읽기 권한
  role       = aws_iam_role.eks_node_group.name
}



# EKS 노드그룹용 CloudWatch Agent 정책 연결
resource "aws_iam_role_policy_attachment" "eks_cw_agent_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# EKS 노드그룹용 CloudWatch Agent 설정 (SSM Parameter Store)
resource "aws_ssm_parameter" "eks_cloudwatch_agent_config" {
  name = "/eks-cloudwatch-agent/config"
  type = "String"
  value = jsonencode({
    agent = {
      metrics_collection_interval = 60
      region                      = "ap-northeast-2"
      debug                       = true
    }
    metrics = {
      namespace = "NineWiki/EKS"
      metrics_collected = {
        mem = {
          measurement                 = ["mem_used_percent"]
          metrics_collection_interval = 60
          resources                   = ["*"]
        }
        cpu = {
          measurement                 = ["cpu_usage_user", "cpu_usage_system", "cpu_usage_idle"]
          metrics_collection_interval = 60
          resources                   = ["*"]
        }
      }
    }
  })

  tags = {
    Name    = "eks-cloudwatch-agent-config"
    Project = "ninewiki"
  }
}

# EKS 노드그룹용 SSM Parameter Store 접근 정책
resource "aws_iam_role_policy" "eks_ssm_policy" {
  name = "eks-ssm-policy"
  role = aws_iam_role.eks_node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:ap-northeast-2:*:parameter/eks/*",
          "arn:aws:ssm:ap-northeast-2:*:parameter/cloudwatch-agent/*"
        ]
      }
    ]
  })
}

# EKS 노드그룹용 X-Ray Write Only Access 정책 연결
resource "aws_iam_role_policy_attachment" "eks_xray_write_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

# EKS 노드그룹용 CloudWatch Agent 추가 정책
resource "aws_iam_role_policy" "eks_cloudwatch_policy" {
  name = "eks-cloudwatch-policy"
  role = aws_iam_role.eks_node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}



# EKS CloudWatch Observability Add-on
resource "aws_eks_addon" "cw_observability" {
  cluster_name = aws_eks_cluster.eks_master.name
  addon_name   = "amazon-cloudwatch-observability"

  depends_on = [
    aws_eks_cluster.eks_master,
    aws_eks_node_group.eks_node_group
  ]

  tags = {
    Name    = "eks-cloudwatch-observability"
    Project = "ninewiki"
  }
}

# EKS CloudWatch Observability Add-on만 사용 (자동으로 CloudWatch Agent 설치)
# 추가 Kubernetes 리소스는 EKS Add-on에서 자동 관리됨





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
    aws_iam_role_policy.eks_ssm_policy,
    aws_iam_role_policy.eks_cloudwatch_policy,
    aws_ssm_parameter.eks_cloudwatch_agent_config
  ]
}









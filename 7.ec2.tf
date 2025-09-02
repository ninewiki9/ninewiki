
# Bastion 호스트 EC2 인스턴스
resource "aws_instance" "pub-ec2-bastion-2a" {
  ami                         = "ami-0fc8aeaa301af7663"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  subnet_id                   = aws_subnet.pub-subnet-2a.id
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  
  tags = {
    Name    = "bastion-host"
    Project = var.project
    Environment = var.environment
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    encrypted   = true
    tags = {
      Name    = "ninewiki-test-bastion-root-volume"
      Project = var.project
      Environment = var.environment
    }
  }
  
  user_data = <<-EOF
    #!/bin/bash
    # AWS CLI v2 설치
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # kubectl 설치
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

    # EKS 클러스터 설정
    # aws eks update-kubeconfig --region ap-northeast-2 --name ninewiki-eks-cluster
    #eksctl 설치
    curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    

    #helm 설치
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    #DB 테이블 설정용 설치
    sudo dnf install -y mariadb105
  EOF
  
  depends_on = [
    aws_eks_node_group.eks_node_group,
    aws_iam_instance_profile.bastion_profile
  ]
}

# Bastion용 IAM 역할
resource "aws_iam_role" "bastion_role" {
  name = "bastion-role"

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

# EKS 클러스터 접근 권한
resource "aws_iam_role_policy" "bastion_eks_policy" {
  name = "bastion-eks-policy"
  role = aws_iam_role.bastion_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM 인스턴스 프로필
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-profile"
  role = aws_iam_role.bastion_role.name
}

# 통계 사이트용 Elastic IP
resource "aws_eip" "statistics_eip" {
  domain = "vpc"
  
  tags = {
    Name    = "statistics-site-eip"
    Project = var.project
    Environment = var.environment
  }
}

resource "aws_instance" "statistic"{
  ami                         = "ami-0fc8aeaa301af7663"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.statistics_sg.id]  # 통계 사이트 전용 보안 그룹 사용
  subnet_id                   = aws_subnet.pub-subnet-2c.id
  key_name                    = var.key_name
  associate_public_ip_address = true

  
  tags = {
    Name    = "statistics site"
    Project = var.project
    Environment = var.environment
  }
}

# Elastic IP를 통계 사이트 EC2에 연결
resource "aws_eip_association" "statistics_eip_assoc" {
  instance_id   = aws_instance.statistic.id
  allocation_id = aws_eip.statistics_eip.id
}

/*
================================================================================
📊 EC2 인스턴스 타입 비교표
================================================================================

현재 사용 중인 인스턴스 타입 (테스트용):
┌─────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│   인스턴스      │   CPU       │   메모리    │   네트워크  │   월 비용   │
│     타입        │   (vCPU)    │   (GB)      │   (Gbps)    │  (한국)     │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│   t3.micro      │     2       │     1       │     최대 5  │   ~$8.5     │
│   (Bastion)     │             │             │             │ (~11,000원) │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│   t3.micro      │     2       │     1       │     최대 5  │   ~$8.5     │
│   (통계사이트)   │             │             │             │ (~11,000원) │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│   t3.medium     │     2       │     4       │     최대 5  │   ~$34      │
│   (EKS 노드)    │             │             │             │ (~45,000원) │
└─────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘

실제 프로덕션 적용 권장 인스턴스 타입:
┌─────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│   인스턴스      │   CPU       │   메모리    │   네트워크  │   월 비용   │
│     타입        │   (vCPU)    │   (GB)      │   (Gbps)    │  (한국)     │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│   t3.small      │     2       │     2       │     최대 5  │   ~$17      │
│   (Bastion)     │             │             │             │ (~22,000원) │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│   t3.small      │     2       │     2       │     최대 5  │   ~$17      │
│   (통계사이트)   │             │             │             │ (~22,000원) │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│   t3.large      │     2       │     8       │     최대 5  │   ~$68      │
│   (EKS 노드)    │             │             │             │ (~90,000원) │
└─────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘

고성능 프로덕션 인스턴스 타입 (대용량 트래픽):
┌─────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│   인스턴스      │   CPU       │   메모리    │   네트워크  │   월 비용   │
│     타입        │   (vCPU)    │   (GB)      │   (Gbps)    │  (한국)     │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│   t3.medium     │     2       │     4       │     최대 5  │   ~$34      │
│   (Bastion)     │             │             │             │ (~45,000원) │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│   t3.medium     │     2       │     4       │     최대 5  │   ~$34      │
│   (통계사이트)   │             │             │             │ (~45,000원) │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│   m5.large      │     2       │     8       │     최대 10 │   ~$85      │
│   (EKS 노드)    │             │             │             │ (~110,000원)│
└─────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘

💡 권장사항:
• 테스트 환경: 현재 설정 유지 (t3.micro)
• 소규모 프로덕션: t3.small로 업그레이드
• 중간 규모 프로덕션: t3.medium 사용
• 대용량 트래픽: m5.large 또는 c5.large 고려

🔧 인스턴스 타입 변경 방법:
1. Terraform 파일에서 instance_type 수정
2. terraform plan으로 변경사항 확인
3. terraform apply로 적용 (EC2 재시작됨)

⚠️ 주의사항:
• 인스턴스 타입 변경 시 EC2가 재시작됩니다
• 데이터 백업 후 진행하세요
• 다운타임이 발생할 수 있습니다
================================================================================
*/
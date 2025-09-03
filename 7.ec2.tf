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
    Name        = "bastion-host"
    Project     = var.project
    Environment = var.environment
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

    # AWS CLI 기본 설정 (IAM 역할을 통한 자동 인증)
    mkdir -p /home/ec2-user/.aws
    cat > /home/ec2-user/.aws/config << 'AWS_CONFIG'
[default]
region = ap-northeast-2
output = json
AWS_CONFIG

    # AWS CLI 자격 증명 설정 (IAM 역할 사용)
    cat > /home/ec2-user/.aws/credentials << 'AWS_CREDENTIALS'
[default]
# IAM 역할을 통해 자동으로 자격 증명이 제공됩니다
# 별도의 access_key_id와 secret_access_key는 필요하지 않습니다
AWS_CREDENTIALS

    # 권한 설정
    chown -R ec2-user:ec2-user /home/ec2-user/.aws
    chmod 600 /home/ec2-user/.aws/credentials
    chmod 644 /home/ec2-user/.aws/config

    # AWS CLI 테스트
    echo "AWS CLI 설정 완료"
    echo "현재 리전: $(aws configure get region)"
    echo "사용 가능한 EKS 클러스터:"
    aws eks list-clusters --region ap-northeast-2 || echo "EKS 클러스터 목록 조회 실패 (IAM 권한 확인 필요)"

    # EKS 클러스터 kubeconfig 자동 설정
    echo "EKS 클러스터 kubeconfig 설정 중..."
    aws eks update-kubeconfig --region ap-northeast-2 --name ninewiki-eks-cluster || echo "EKS 클러스터 연결 실패"
    
    # kubectl 설정 확인
    echo "kubectl 설정 확인:"
    kubectl cluster-info || echo "kubectl 연결 실패"
    kubectl get nodes || echo "노드 정보 조회 실패"
    
    echo "Bastion 서버 설정 완료!"
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



resource "aws_instance" "statistic" {
  ami                         = "ami-0fc8aeaa301af7663"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.statistics_sg.id] # 통계 사이트 전용 보안 그룹 사용
  subnet_id                   = aws_subnet.pub-subnet-2c.id
  key_name                    = var.key_name
  associate_public_ip_address = true


  user_data = <<-EOF
    #!/bin/bash
    set -e  # 오류 발생 시 스크립트 중단
    
    # 로그 파일 설정
    exec > >(tee /var/log/user-data.log) 2>&1
    
    echo "=== User Data Script 시작 ==="
    
    # 시스템 업데이트
    sudo dnf update -y
    
    # Docker 설치 및 시작
    echo "Docker 설치 중..."
    sudo dnf install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 도커 이미지 적용용
    echo "Docker 이미지 다운로드 및 실행 중..."
    sudo docker login -u ${var.docker_username} -p ${var.docker_password}
    sudo docker pull ${var.docker_username}/wiki-stats
    sudo docker run -d -p 8000:8000 --name wiki-stats ${var.docker_username}/wiki-stats


    
    echo "=== User Data Script 완료 ==="
  EOF



  tags = {
    Name        = "statistics site"
    Project     = var.project
    Environment = var.environment
  }
}
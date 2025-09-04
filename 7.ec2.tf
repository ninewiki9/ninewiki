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
set -e
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== User Data Script 시작 ==="
echo "시작 시간: $(date)"

# AWS CLI v2 설치
echo "AWS CLI v2 설치 중..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

# kubectl 설치
echo "kubectl 설치 중..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# eksctl 설치
echo "eksctl 설치 중..."
curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# helm 설치
echo "helm 설치 중..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# MariaDB 설치
echo "MariaDB 설치 중..."
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
          "eks:AccessKubernetesApi",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeAddon",
          "eks:ListAddons"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeRouteTables"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
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

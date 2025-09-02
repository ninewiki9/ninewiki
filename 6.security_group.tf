# Bastion 보안 그룹
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = aws_vpc.ninewiki-test-vpc.id

  tags = {
    Name    = "bastion-sg"
    Project = var.project
    Environment = var.environment
  }

  # SSH 접속 허용
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # 모든 아웃바운드 트래픽 허용 (DB 연결 포함)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# 통계 사이트 보안 그룹
resource "aws_security_group" "statistics_sg" {
  name        = "statistics-sg"
  description = "Security group for Statistics site"
  vpc_id      = aws_vpc.ninewiki-test-vpc.id

  tags = {
    Name    = "statistics-sg"
    Project = var.project
    Environment = var.environment
  }

  # HTTP 접근 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS 접근 허용
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ALB에서 HTTP 트래픽 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # ALB에서 HTTPS 트래픽 허용
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # ALB에서 8080 포트 트래픽 허용
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # SSH 접근 허용 (Bastion에서만)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks= ["0.0.0.0/0"]
    }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB 보안 그룹
resource "aws_security_group" "db_sg" {
  name        = "DB-sg"
  description = "Security group for Database instances"
  vpc_id      = aws_vpc.ninewiki-test-vpc.id

  tags = {
    Name    = "db-sg"
    Project = var.project
    Environment = var.environment
  }


  # EKS 워커/클러스터 + Bastion등 같은 vpc내에서 접근 허용
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
    
  }
  
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EKS 클러스터 보안 그룹
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.ninewiki-test-vpc.id

  # EKS API 서버 접근 (kubectl)만 유지
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id, aws_security_group.eks_worker_sg.id]
  }

  # HTTP 접근 (ALB에서)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "eks-cluster-sg"
    Project = var.project
    Environment = var.environment
  }
}

# EKS 워커 노드 보안 그룹
resource "aws_security_group" "eks_worker_sg" {
  name        = "eks-worker-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.ninewiki-test-vpc.id

  # kubelet API (노드 간 통신)
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }

  # kube-proxy 헬스체크
  ingress {
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    self        = true
  }

  # NodePort 서비스 범위 (ALB에서 접근 허용)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # CoreDNS
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    self        = true
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    self        = true
  }

  # CoreDNS 메트릭스
  ingress {
    from_port   = 9153
    to_port     = 9153
    protocol    = "tcp"
    self        = true
  }

  # HTTP 트래픽 (ALB에서 접근 허용)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # HTTPS 트래픽 (ALB에서 접근 허용)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }



  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "eks-worker-sg"
    Project = var.project
    Environment = var.environment
  }
}

#alb 보안 그룹
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB SG for EKS NGINX Ingress"
  vpc_id      = aws_vpc.ninewiki-test-vpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "ALL"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "alb-sg"
    Project = var.project
    Environment = var.environment
  }
}

# EKS 클러스터에서 노드그룹으로의 통신 허용 (순환 참조 방지)
resource "aws_security_group_rule" "nodes_from_cluster_10250" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}

# EKS 클러스터에서 노드그룹으로의 443 포트 통신 허용
resource "aws_security_group_rule" "nodes_from_cluster_443" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}
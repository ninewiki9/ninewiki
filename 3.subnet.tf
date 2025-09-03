resource "aws_subnet" "pub-subnet-2a" {
  vpc_id                  = aws_vpc.ninewiki-vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = "true" #자동 ip할당
  tags = {
    Name = "bastion"

  }
}

resource "aws_subnet" "pub-subnet-2c" {
  vpc_id                  = aws_vpc.ninewiki-vpc.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = "true" #자동 ip할당
  tags = {
    Name = "statistic"

  }
}

resource "aws_subnet" "pri-subnet-2a" {
  vpc_id                  = aws_vpc.ninewiki-vpc.id
  cidr_block              = "10.10.3.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = "false" #자동 ip할당 X
  tags = {
    Name = "eks2"
  }
}

resource "aws_subnet" "pri-subnet-2c" {
  vpc_id                  = aws_vpc.ninewiki-vpc.id
  cidr_block              = "10.10.4.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "eks1"

  }
}
resource "aws_subnet" "pri-subnet-db-2a" {
  vpc_id                  = aws_vpc.ninewiki-vpc.id
  cidr_block              = "10.10.5.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = "false" #자동 ip할당 X
  tags = {
    Name = "DB1"
  }
}

resource "aws_subnet" "pri-subnet-db-2c" {
  vpc_id                  = aws_vpc.ninewiki-vpc.id
  cidr_block              = "10.10.6.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "DB2"

  }
}

resource "aws_subnet" "pub-alb-subnet1" {
  vpc_id                  = aws_vpc.ninewiki-vpc.id
  cidr_block              = "10.10.7.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = "true" #자동 ip할당
  tags = {
    Name                                         = "alb1"
    "kubernetes.io/role/elb"                     = "1"      # ALB용 태그
    "kubernetes.io/cluster/ninewiki-eks-cluster" = "shared" # EKS 클러스터 태그
  }
}

resource "aws_subnet" "pub-alb-subnet2" {
  vpc_id                  = aws_vpc.ninewiki-vpc.id
  cidr_block              = "10.10.8.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = "true" #자동 ip할당
  tags = {
    Name                                         = "alb2"
    "kubernetes.io/role/elb"                     = "1"      # ALB용 태그
    "kubernetes.io/cluster/ninewiki-eks-cluster" = "shared" # EKS 클러스터 태그
  }
}

#퍼블릭 라우팅 테이블 생성
resource "aws_route_table" "pub-rtable" {
  vpc_id = aws_vpc.ninewiki-vpc.id
  tags = {
    Name = "pub_rt"
  }
}
#프라이빗 라우팅 테이블 생성
resource "aws_route_table" "pri-rtable" {
  vpc_id = aws_vpc.ninewiki-vpc.id
  tags = {
    Name = "pri_rt"
  }
}
#라우팅 테이블에 게이트웨이 연결  
resource "aws_route" "pub-rt" {
  route_table_id         = aws_route_table.pub-rtable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ninewiki-igw.id
}
#프라이빗 라우팅 테이블에 NAT 게이트웨이 연결결
resource "aws_route" "pri-rt" {
  route_table_id         = aws_route_table.pri-rtable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.ninewiki-ngw.id
}

resource "aws_route_table_association" "pub-rtable-association" {
  subnet_id      = aws_subnet.pub-subnet-2a.id
  route_table_id = aws_route_table.pub-rtable.id
}

resource "aws_route_table_association" "pub-rtable-association-2c" {
  subnet_id      = aws_subnet.pub-subnet-2c.id
  route_table_id = aws_route_table.pub-rtable.id
}
resource "aws_route_table_association" "pub-rtable-association-alb1" {
  subnet_id      = aws_subnet.pub-alb-subnet1.id
  route_table_id = aws_route_table.pub-rtable.id
}

resource "aws_route_table_association" "pub-rtable-association-alb2" {
  subnet_id      = aws_subnet.pub-alb-subnet2.id
  route_table_id = aws_route_table.pub-rtable.id
}


# EKS 서브넷 라우팅 테이블 연결
resource "aws_route_table_association" "pri-rtable-association-eks-2a" {
  subnet_id      = aws_subnet.pri-subnet-2a.id
  route_table_id = aws_route_table.pri-rtable.id
}
resource "aws_route_table_association" "pri-rtable-association-eks-2c" {
  subnet_id      = aws_subnet.pri-subnet-2c.id
  route_table_id = aws_route_table.pri-rtable.id
}

# DB 서브넷 라우팅 테이블 연결
resource "aws_route_table_association" "pri-rtable-association-db-2a" {
  subnet_id      = aws_subnet.pri-subnet-db-2a.id
  route_table_id = aws_route_table.pri-rtable.id
}
resource "aws_route_table_association" "pri-rtable-association-db-2c" {
  subnet_id      = aws_subnet.pri-subnet-db-2c.id
  route_table_id = aws_route_table.pri-rtable.id
}

#인터넷 게이트웨이 생성
resource "aws_internet_gateway" "ninewiki-igw" {
  vpc_id = aws_vpc.ninewiki-vpc.id
  tags = {
    "Name" = "ninewiki-igw"
  }

}
# 탄력적 IP 생성
resource "aws_eip" "ninewiki-eip" {
  domain = "vpc"
}
#NAT 게이트웨이 생성 
resource "aws_nat_gateway" "ninewiki-ngw" {
  allocation_id = aws_eip.ninewiki-eip.id
  subnet_id     = aws_subnet.pub-subnet-2a.id
  tags = {
    "Name" = "ninewiki-ngw"
  }
}
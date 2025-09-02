#인터넷 게이트웨이 생성
resource "aws_internet_gateway" "test-igw" {
  vpc_id = aws_vpc.ninewiki-test-vpc.id
  tags = {
    "Name" = "ninewiki-test-igw"
  }

}
# 탄력적 IP 생성
resource "aws_eip" "ninewiki-test-eip" {
  domain = "vpc"
}
#NAT 게이트웨이 생성 
resource "aws_nat_gateway" "test-ngw" {
  allocation_id = aws_eip.ninewiki-test-eip.id
  subnet_id =  aws_subnet.pub-subnet-2a.id
  tags = {
    "Name" = "ninewiki-test-ngw"
  } 
}
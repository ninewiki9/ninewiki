resource "aws_vpc" "ninewiki-test-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true           # VPC 내에서 DNS 쿼리를 처리할지 여부를 결정
  enable_dns_hostnames = true       # VPC 내에서 DNS 호스트 이름을 활성화할지 여부를 결정
  tags = {
    "Name" = "ninewiki-test-vpc"
  }
}

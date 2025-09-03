resource "aws_vpc" "ninewiki-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true # VPC 내에서 DNS 쿼리를 처리할지 여부를 결정
  enable_dns_hostnames = true # VPC 내에서 DNS 호스트 이름을 활성화할지 여부를 결정

  enable_network_address_usage_metrics = true #네트워크 모니터링 설정
  tags = {
    "Name" = "ninewiki-vpc"
  }
}

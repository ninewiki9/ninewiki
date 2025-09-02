# 기존 ACM 인증서 가져오기
data "aws_acm_certificate" "dns_certificate" {
  domain = "ninewiki.store"
  statuses = ["ISSUED"]
}

# Route53 호스팅 영역 생성
resource "aws_route53_zone" "main" {
  name = "ninewiki.store"

  tags = {
    Name    = "ninewiki-store-zone"
    Project = "ninewiki-test"
  }
}

resource "aws_route53_record" "cname"{
  zone_id = aws_route53_zone.main.id
  name    = "_bbab50caf90af9ada0cc5d756c5469e3.ninewiki.store"             #cname 이름
  records = ["_96b8f1edaf55934186ea15c210653643.xlfgrmvvlj.acm-validations.aws"] #cname 값
  type    = "CNAME"
  ttl     = "300"
}

/*# ACM 인증서 데이터 출력
output "acm_certificate_arn" {
  description = "ACM 인증서 ARN"
  value       = data.aws_acm_certificate.dns_certificate.arn
}*/



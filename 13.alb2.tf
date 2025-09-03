# Application Load Balancer
variable "node_asg_names" {
  description = "ALB Target Group에 연결할 ASG 이름 리스트 (EKS 노드그룹의 ASG명)"
  type        = list(string)
  default     = [] # tfvars에서 채워주세요
}

locals {
  # 임시로 고정된 NodePort 값 사용 (EKS 생성 후 실제 값으로 변경)
  nodeport_http  = 30080 # 임시 값 (nginx-ingress Service의 NodePort와 일치해야 함)
  nodeport_https = 30443 # 임시 값 (nginx-ingress Service의 NodePort와 일치해야 함)
}

# ALB (Public)
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets = [
    aws_subnet.pub-alb-subnet1.id, # ap-northeast-2a
    aws_subnet.pub-alb-subnet2.id  # ap-northeast-2c
  ]
  security_groups = [aws_security_group.alb.id]

  enable_deletion_protection = false
}

# Target Groups (instance target)
resource "aws_lb_target_group" "http" {
  name        = "${var.name}-tg-http"
  port        = local.nodeport_http
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.ninewiki-vpc.id

  # NGINX Ingress Controller 헬스 체크
  health_check {
    path                = "/healthz" # /, /health, /healthz 등 가능
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 15
    matcher             = "200-499"
  }
}

resource "aws_lb_target_group" "https" {
  name        = "${var.name}-tg-https"
  port        = local.nodeport_https
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = aws_vpc.ninewiki-vpc.id

  health_check {
    path                = "/healthz"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200-499"
  }
}

# 통계 사이트용 Target Group (별도 EC2 8000 포트)
resource "aws_lb_target_group" "statistics" {
  name        = "${var.name}-tg-statistics"
  port        = 8000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.ninewiki-vpc.id

  health_check {
    path                = "/health" # 헬스체크 엔드포인트
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200-499"
  }
}

# Listeners & Rules
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS 리스너 (기존 ACM 인증서 사용)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.dns_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https.arn
  }
}

# 통계 사이트 라우팅 규칙
resource "aws_lb_listener_rule" "statistics" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.statistics.arn
  }

  condition {
    path_pattern {
      values = ["/statistics*", "/stats*"]
    }
  }

  depends_on = [aws_lb_target_group.statistics]
}

# Target Group Attachments

# HTTP Target Group에 ASG 연결
resource "aws_autoscaling_attachment" "tg_http_asg" {
  for_each               = toset(var.node_asg_names) # ← Plan 시점 확정
  autoscaling_group_name = each.value
  lb_target_group_arn    = aws_lb_target_group.http.arn
  depends_on = [aws_eks_node_group.eks_node_group]
}

# HTTPS Target Group에 ASG 연결
resource "aws_autoscaling_attachment" "tg_https_asg" {
  for_each               = toset(var.node_asg_names) # ← Plan 시점 확정
  autoscaling_group_name = each.value
  lb_target_group_arn    = aws_lb_target_group.https.arn
  depends_on = [aws_eks_node_group.eks_node_group]
}

# 통계 사이트 Target Group Attachment (단일 EC2)
resource "aws_lb_target_group_attachment" "statistics" {
  target_group_arn = aws_lb_target_group.statistics.arn
  target_id        = aws_instance.statistic.id
  port             = 8000 # Target Group의 포트와 일치

  depends_on = [aws_lb_target_group.statistics]
}

# www 서브도메인 Route53 레코드
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.ninewiki.store"
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

# 와일드카드 서브도메인 Route53 레코드 (*)
resource "aws_route53_record" "wildcard" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "*.ninewiki.store"
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

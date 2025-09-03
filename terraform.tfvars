# ==========================================
# Terraform 변수 값 설정
# ==========================================

# AWS 리전
region = "ap-northeast-2"

# EKS 클러스터 이름
cluster_name = "ninewiki-eks-cluster"

# 자동으로 생성된 리소스 ID들은 직접 참조하므로 여기서 설정할 필요가 없습니다.
# VPC, 서브넷, 보안 그룹 등은 Terraform 코드에서 직접 참조됩니다.

# 리소스 이름 접두사
name = "ninewiki"

# NGINX 설정
nginx_namespace    = "ingress-nginx"
nginx_service_name = "ingress-nginx-controller"

# HTTPS 설정
enable_https           = true
redirect_http_to_https = true

# ACM 인증서 ARN (ACM 인증서 생성 후 설정)
# acm_certificate_arn = "arn:aws:acm:ap-northeast-2:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# 헬스 체크 경로
health_check_path = "/"

# 키 페어 이름
key_name = "ninewiki_key"

# 프로젝트 태그
project     = "ninewiki-test"
environment = "test"

# Docker Hub 인증 정보
docker_username = "jyhak7741"
docker_password = "j07127741"

# worker_security_group_ids는 Terraform에서 직접 참조하므로 제거
# worker_security_group_ids= ["sg-05b2159300b5ecf85","sg-05b2159300b5ecf85"]
node_asg_names = [
  "eks-ninewiki-eks-node-group-80cc8678-178d-5ef9-8870-41655df036d6",
]

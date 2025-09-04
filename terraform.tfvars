# ==========================================
# Terraform 변수 값 설정
# ==========================================

# AWS 리전
region = "ap-northeast-2"

# EKS 클러스터 이름
cluster_name = "ninewiki-eks-cluster"

# 리소스 이름 접두사
name = "ninewiki"

# 키 페어 이름
key_name = "ninewiki_key"

# 프로젝트 태그
project     = "ninewiki-test"
environment = "test"

# Docker Hub 인증 정보
docker_username = "jyhak7741"
# docker_password는 환경 변수나 별도 파일에서 설정
docker_password = "j07127741"

# ==========================================
# Terraform 변수 정의
# ==========================================

# AWS 리전
variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# EKS 클러스터 이름
variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "ninewiki-eks-cluster"
}

# VPC ID (자동으로 생성된 VPC 사용)
variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "" # 빈 문자열로 설정하여 자동 참조 사용
}

# 퍼블릭 서브넷 ID 목록 (자동으로 생성된 서브넷 사용)
variable "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  type        = list(string)
  default     = [] # 빈 배열로 설정하여 자동 참조 사용
}

# EKS 노드 그룹 ASG 이름 목록
#variable "node_group_asg_names" {
#  description = "EKS 노드 그룹 Auto Scaling Group 이름 목록"
#  type        = list(string)
#  default     = []
#}

# 워커 노드 보안 그룹 ID 목록 (자동으로 생성된 보안 그룹 사용)
variable "worker_security_group_ids" {
  description = "EKS 워커 노드 보안 그룹 ID 목록"
  type        = list(string)
  default     = [] # 빈 배열로 설정하여 자동 참조 사용
}

# 리소스 이름 접두사
variable "name" {
  description = "리소스 이름 접두사"
  type        = string
  default     = "ninewiki"
}

# NGINX 네임스페이스
variable "nginx_namespace" {
  description = "NGINX Ingress Controller 네임스페이스"
  type        = string
  default     = "ingress-nginx"
}

# NGINX 서비스 이름
variable "nginx_service_name" {
  description = "NGINX Ingress Controller 서비스 이름"
  type        = string
  default     = "ingress-nginx-controller"
}

# HTTPS 활성화 여부
variable "enable_https" {
  description = "HTTPS 활성화 여부"
  type        = bool
  default     = true
}

# HTTP to HTTPS 리다이렉트 여부
variable "redirect_http_to_https" {
  description = "HTTP to HTTPS 리다이렉트 여부"
  type        = bool
  default     = true
}

# ACM 인증서 ARN
variable "acm_certificate_arn" {
  description = "ACM 인증서 ARN"
  type        = string
  default     = null
}

# 헬스 체크 경로
variable "health_check_path" {
  description = "헬스 체크 경로"
  type        = string
  default     = "/"
}

# 키 페어 이름
variable "key_name" {
  description = "EC2 키 페어 이름"
  type        = string
  default     = "ninewiki_key"
}

# Docker Hub 인증 정보
variable "docker_username" {
  description = "Docker Hub 사용자명"
  type        = string
  default     = "jyhak7741"
}

variable "docker_password" {
  description = "Docker Hub 비밀번호"
  type        = string
  sensitive   = true
}

# 프로젝트 태그
variable "project" {
  description = "프로젝트 태그"
  type        = string
  default     = "ninewiki"
}

# 환경 태그
variable "environment" {
  description = "환경 태그"
  type        = string
  default     = "prod"
}



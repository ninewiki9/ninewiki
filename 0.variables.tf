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



# 리소스 이름 접두사
variable "name" {
  description = "리소스 이름 접두사"
  type        = string
  default     = "ninewiki"
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


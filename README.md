# NineWiki Infrastructure

NineWiki 프로젝트를 위한 AWS 인프라를 Terraform으로 관리하는 저장소입니다.

## 🏗️ 인프라 구성

### 핵심 구성 요소
- **VPC & 네트워킹**: 프라이빗/퍼블릭 서브넷, NAT Gateway, Route Tables
- **EKS 클러스터**: Kubernetes 클러스터 및 노드 그룹
- **Application Load Balancer**: EKS 서비스 및 통계 사이트 로드 밸런싱
- **RDS**: MySQL 데이터베이스
- **EC2 인스턴스**: Bastion 호스트, 통계 사이트
- **보안 그룹**: 각 서비스별 세밀한 접근 제어

### 아키텍처 개요
```
Internet → ALB → EKS (NodePort) / 통계 사이트 (8000)
                ↓
            EKS 워커 노드 (t3.medium)
                ↓
            RDS MySQL (프라이빗 서브넷)
```

## 🚀 시작하기

### 사전 요구사항
- Terraform >= 1.0
- AWS CLI v2
- kubectl
- Docker

### 1. 저장소 클론
```bash
git clone <repository-url>
cd ninewiki-infrastructure
```

### 2. AWS 자격 증명 설정
```bash
# 방법 1: AWS CLI 설정
aws configure

# 방법 2: 환경 변수
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="ap-northeast-2"
```

### 3. 민감한 정보 설정
```bash
# Docker Hub 비밀번호 설정
export TF_VAR_docker_password="your_docker_password"

# 또는 terraform.tfvars.local 파일 생성 (Git에 추가하지 않음)
echo 'docker_password = "your_password"' > terraform.tfvars.local
```

### 4. Terraform 실행
```bash
# 초기화
terraform init

# 계획 확인
terraform plan

# 인프라 생성
terraform apply
```

## 📁 파일 구조

```
├── 0.variables.tf          # 변수 정의
├── 1.provider.tf           # AWS 프로바이더 설정
├── 2.vpc.tf               # VPC 및 CIDR 설정
├── 3.subnet.tf            # 서브넷 구성
├── 4.gateway.tf           # Internet/NAT Gateway
├── 5.routing_table.tf     # 라우팅 테이블
├── 6.security_group.tf    # 보안 그룹
├── 7.ec2.tf              # EC2 인스턴스
├── 8.eks.tf              # EKS 클러스터
├── 9.eks_nodegroup.tf    # EKS 노드 그룹
├── 10.rds.tf             # RDS 데이터베이스
├── 12.acm&route53.tf     # SSL 인증서 및 DNS
├── 13.alb2.tf            # Application Load Balancer
├── 14.cloudwatch11.tf    # CloudWatch 모니터링
├── terraform.tfvars       # 변수 값 설정
└── README.md              # 이 파일
```

## 🔧 주요 설정

### EKS 클러스터
- **클러스터 이름**: `ninewiki-eks-cluster`
- **노드 그룹**: `t3.medium` 인스턴스 3-5개
- **리전**: `ap-northeast-2` (서울)

### 네트워킹
- **VPC CIDR**: `10.10.0.0/16`
- **퍼블릭 서브넷**: `10.10.1.0/24`, `10.10.3.0/24`
- **프라이빗 서브넷**: `10.10.2.0/24`, `10.10.4.0/24`

### 보안
- **Bastion 호스트**: SSH 접근 (포트 22)
- **EKS 워커 노드**: NodePort 서비스 (30000-32767)
- **통계 사이트**: ALB를 통한 접근만 허용 (포트 8000)
- **RDS**: VPC 내부에서만 접근 (포트 3306)

## 🛡️ 보안 고려사항

### 민감한 정보 관리
- `docker_password`는 환경 변수로 설정

### 접근 제어
- Bastion 호스트를 통한 SSH 접근만 허용
- EKS 클러스터는 프라이빗 서브넷에 배치
- RDS는 VPC 내부에서만 접근 가능

## 📊 모니터링

### CloudWatch
- EKS 클러스터 및 노드 그룹 메트릭 수집
- 컨테이너 인사이트 활성화
- 로그 수집 및 분석

### 로그 관리
- EKS 클러스터 로그
- 애플리케이션 로그
- 시스템 로그

## 🔄 업데이트 및 유지보수

### 인프라 업데이트
```bash
# 변경사항 확인
terraform plan

# 업데이트 적용
terraform apply
```

### 특정 리소스만 업데이트
```bash
# 특정 리소스 타겟팅
terraform apply -target=aws_eks_node_group.eks_node_group
```

### Run 후에 aws configure 하고 aws eks update-kubeconfig --region ap-northeast-2 --name ninewiki-eks-cluster 로 kubectle 설정 만들어야함






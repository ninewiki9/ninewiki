# RDS 서브넷 그룹 생성
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "ninewiki-db-subnet-group"
  subnet_ids = [aws_subnet.pri-subnet-db-2a.id, aws_subnet.pri-subnet-db-2c.id]

  tags = {
    Name    = "ninewiki-db-subnet-group"
    Project = "ninewiki"
  }
}

# DB 파라미터 그룹 생성 (한글 지원)
resource "aws_db_parameter_group" "db_parameter_group" {
  family = "mysql8.0"
  name   = "ninewiki-db-parameter-group"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4" # 서버 기본 문자셋 (한글, 이모지 지원)
  }
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci" # 문자열 정렬 규칙 (대소문자 구분 없음)
  }
  # 네트워크 성능 최적화 파라미터
  parameter {
    name  = "max_connections"
    value = "200" # 동시 연결 가능한 최대 클라이언트 수
  }
  parameter {
    name  = "innodb_flush_log_at_trx_commit"
    value = "1" # 트랜잭션 커밋 시 로그 플러시 (1=ACID 보장, 0=성능 우선)
  }
  parameter {
    name  = "innodb_flush_method"
    value = "O_DIRECT" # 디스크 I/O 방식 (O_DIRECT=캐시 우회로 성능 향상)
  }
  tags = {
    Name    = "ninewiki-db-parameter-group"
    Project = "ninewiki"
  }
}

resource "aws_db_instance" "default" {
  identifier        = "ninewiki-db" # AWS 콘솔에서 보이는 이름
  allocated_storage = 10
  db_name           = "ninewiki" #mysql에 생기는 Database 이름
  engine            = "mysql"
  engine_version    = "8.0.42"      #AWS에 Database생성 했을 때 기본으로 되어있는 버전
  instance_class    = "db.t3.micro" # 현재 설정

  # 인스턴스 크기 설정 가이드:
  # - db.t3.micro (현재): 개발/테스트용, 1GB RAM, ~$15/월
  # - db.t3.small: 소규모 위키, 2GB RAM, ~$30/월
  # - db.t3.medium: 중간 규모 위키, 4GB RAM, ~$60/월
  # - db.r5.large: 대용량 위키, 16GB RAM, ~$240/월
  # - db.m5.large: 균형잡힌 성능, 8GB RAM, ~$120/월

  username               = "admin"
  password               = "12341234" #접속 비밀번호
  parameter_group_name   = aws_db_parameter_group.db_parameter_group.name
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  depends_on = [
    aws_db_subnet_group.rds_subnet_group,
    aws_db_parameter_group.db_parameter_group,
    aws_security_group.db_sg
  ]

  # 네트워크 성능 향상 설정
  monitoring_interval = 0 # Enhanced Monitoring 비활성화 (비용 절약)
  # monitoring_role_arn = null  # IAM 역할이 필요하면 설정

  # I/O 최적화 설정
  storage_type = "gp2" # General Purpose SSD (자동 IOPS 관리)
  # iops = 1000  # GP2에서는 설정 불필요 (자동으로 3 IOPS/GB 할당)

  # IOPS 설정 가이드:
  # - GP2: 자동 관리 (3 IOPS/GB), 현재 10GB = 30 IOPS
  # - IO1: 수동 설정 (50:1 비율), 1000 IOPS = 최소 20GB 필요
  # - IO2: 수동 설정 (500:1 비율), 1000 IOPS = 최소 2GB 필요
  # - 비용: GP2 < IO2 < IO1 순으로 저렴
  # - 성능: GP2(30 IOPS) < IO1(1000 IOPS) < IO2(1000 IOPS) 순으로 빠름

  # 네트워크 대역폭 최적화를 위한 추가 설정
  multi_az            = false # 단일 AZ (비용 절약)
  publicly_accessible = false # 외부 접속 허용 (개발/테스트용)

  /*  # 백업 설정
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  */
  # 암호화 설정
  storage_encrypted = false #aws kms키를 이용하여 암호화

  # 삭제 보호
  deletion_protection = false

  # 최종 스냅샷 건너뛰기
  skip_final_snapshot = true

  # 태그 추가
  tags = {
    Name    = "ninewiki-mysql-instance"
    Project = "ninewiki"
  }
}

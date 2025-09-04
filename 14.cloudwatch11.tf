# Auto-discovery for dashboards
locals {
  statistics_instance_id = aws_instance.statistic.id
}
# ALB created by your stack — 직접 aws_lb 리소스 참조
locals {
  region_name      = "ap-northeast-2"
  alb_dimension    = aws_lb.this.arn_suffix  # e.g., app/ninewiki-alb/xxxxxxxxxxxxxxxx
  rds_identifier   = "ninewiki-db"                    # Adjust here if your DB identifier differs
  eks_cluster_name = "ninewiki-eks-cluster"           # EKS 클러스터 이름
}

# Ninewiki Infra Dashboard (EC2, RDS)
resource "aws_cloudwatch_dashboard" "ninewiki_dashboard" {
  dashboard_name = "ninewiki-monitoring-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type": "metric", "x": 0, "y": 0, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/EC2", "CPUUtilization", "InstanceId", local.statistics_instance_id],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", local.rds_identifier]
          ],
          "period": 300, "stat": "Average", "region": local.region_name,
          "title": "CPU 사용률 (EC2 & RDS)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 0, "y": 6, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/EC2", "NetworkOut", "InstanceId", local.statistics_instance_id],
            ["AWS/EC2", "NetworkIn", "InstanceId", local.statistics_instance_id]
          ],
          "period": 300, "stat": "Average", "region": local.region_name,
          "title": "Statistics EC2 네트워크 (Bytes)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 12, "y": 6, "width": 6, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", local.rds_identifier]
          ],
          "period": 300, "stat": "Average", "region": local.region_name,
          "title": "RDS 연결 수", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 18, "y": 6, "width": 6, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", local.rds_identifier]
          ],
          "period": 300, "stat": "Average", "region": local.region_name,
          "title": "RDS 저장공간 (Bytes)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 0, "y": 12, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", local.rds_identifier],
            ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", local.rds_identifier],
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", local.rds_identifier]
          ],
          "period": 300, "stat": "Average", "region": local.region_name,
          "title": "RDS IOPS/Latency", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 0, "y": 18, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", local.statistics_instance_id]
          ],
          "period": 60, "stat": "Maximum", "region": local.region_name,
          "title": "EC2 StatusCheckFailed (1 => 문제)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 12, "y": 18, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/EC2", "DiskReadBytes", "InstanceId", local.statistics_instance_id],
            ["AWS/EC2", "DiskWriteBytes", "InstanceId", local.statistics_instance_id]
          ],
          "period": 300, "stat": "Average", "region": local.region_name,
          "title": "EC2 Disk Read/Write (Bytes)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 0, "y": 24, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", local.rds_identifier],
            ["AWS/RDS", "SwapUsage", "DBInstanceIdentifier", local.rds_identifier],
            ["AWS/RDS", "DiskQueueDepth", "DBInstanceIdentifier", local.rds_identifier]
          ],
          "period": 300, "stat": "Average", "region": local.region_name,
          "title": "RDS FreeableMemory / Swap / DiskQueueDepth", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 12, "y": 24, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["ContainerInsights","node_cpu_utilization","ClusterName",local.eks_cluster_name],
            ["ContainerInsights","node_memory_utilization","ClusterName",local.eks_cluster_name]
          ],
          "period": 300, "stat": "Average",
          "region": local.region_name,
          "title": "EKS Node Utilization (CPU & Memory)",
          "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 0, "y": 30, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["ContainerInsights","pod_number_of_container_restarts","ClusterName",local.eks_cluster_name]
          ],
          "period": 300, "stat": "Sum",
          "region": local.region_name,
          "title": "Pod Container Restarts",
          "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 12, "y": 30, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/RDS", "ReadThroughput", "DBInstanceIdentifier", local.rds_identifier],
            ["AWS/RDS", "WriteThroughput", "DBInstanceIdentifier", local.rds_identifier]
          ],
          "period": 300, "stat": "Average", "region": local.region_name,
          "title": "RDS Read/Write Throughput (Bytes/s)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 0, "y": 36, "width": 24, "height": 6,
        "properties": {
          "metrics": [
            ["ContainerInsights","node_network_total_bytes","ClusterName",local.eks_cluster_name]
          ],
          "period": 300, "stat": "Average",
          "region": local.region_name,
          "title": "EKS Node Network Total (B/s)",
          "view": "timeSeries", "stacked": false
        }
      }
]
  })
}
# ALB-only Dashboard (auto-detected ALB)
resource "aws_cloudwatch_dashboard" "ninewiki_alb_dashboard" {
  dashboard_name = "ninewiki-alb-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type": "metric", "x": 0, "y": 0, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_dimension]
          ],
          "period": 300, "stat": "Sum", "region": local.region_name,
          "title": "ALB RequestCount (Sum)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 12, "y": 0, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_dimension]
          ],
          "period": 300, "stat": "Sum", "region": local.region_name,
          "title": "Target 5XX (Sum)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 0, "y": 6, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.alb_dimension]
          ],
          "period": 300, "stat": "Sum", "region": local.region_name,
          "title": "ELB 5XX (Sum)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 12, "y": 6, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", local.alb_dimension]
          ],
          "period": 300, "stat": "Sum", "region": local.region_name,
          "title": "ELB 4XX (Sum)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 0, "y": 12, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_dimension]
          ],
          "period": 300, "stat": "p95", "region": local.region_name,
          "title": "TargetResponseTime (p95)", "view": "timeSeries", "stacked": false
        }
      },
      {
        "type": "metric", "x": 12, "y": 12, "width": 12, "height": 6,
        "properties": {
          "metrics": [
            ["AWS/ApplicationELB", "NewConnectionCount", "LoadBalancer", local.alb_dimension]
          ],
          "period": 300, "stat": "Sum", "region": local.region_name,
          "title": "NewConnectionCount (Sum)", "view": "timeSeries", "stacked": false
        }
      }
    ]
  })
}

#!/bin/bash
set -e

# EKS 부트스트랩 스크립트
/etc/eks/bootstrap.sh ${cluster_name} ${bootstrap_extra_args}

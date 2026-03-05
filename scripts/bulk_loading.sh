#!/bin/bash

if [ -z "$1" ]; then
    echo "사용법: $0 <record_count>"
    echo "예시: $0 1000000"
    exit 1
fi

NAMESPACE="default"
POD_NAME="redis"        # Redis Pod 이름으로 수정
CONTAINER_NAME="redis"    # 컨테이너 이름 (필요 없으면 제거 가능)

RECORD_COUNT=$1


kubectl exec -n $NAMESPACE $POD_NAME -c $CONTAINER_NAME -- \
    redis-cli DEBUG POPULATE $RECORD_COUNT


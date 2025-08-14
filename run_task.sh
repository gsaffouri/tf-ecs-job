#!/usr/bin/env bash
set -euo pipefail

REGION="${REGION:-us-east-1}"
CLUSTER="$(terraform output -raw cluster_name)"
TASK_DEF_ARN="$(terraform output -raw task_definition_arn)"
SG_ID="$(terraform output -raw security_group_id)"
SUBNETS_JSON="$(terraform output -json subnet_ids | jq -r 'join(",")')"

echo "[info] Running task on cluster: $CLUSTER"
aws ecs run-task \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --launch-type FARGATE \
  --task-definition "$TASK_DEF_ARN" \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS_JSON],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --count 1 \
  --query "tasks[0].taskArn" \
  --output text

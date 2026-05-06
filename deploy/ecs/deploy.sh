#!/usr/bin/env bash
set -euo pipefail

# ─── Fill these in once ───────────────────────────────────────────────────────
AWS_REGION="us-east-2"
AWS_ACCOUNT_ID="570823560193"
ECS_CLUSTER="default"
ECS_SERVICE="libra-arcana-web"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPO="${ECR_REGISTRY}/libra_arcana"
TASK_DEF_FILE="$(cd "$(dirname "$0")" && pwd)/task_definition.json"
# ─────────────────────────────────────────────────────────────────────────────

IMAGE_TAG="${1:-$(git rev-parse --short HEAD)}"
FULL_IMAGE="${ECR_REPO}:${IMAGE_TAG}"

echo "==> Building image (linux/amd64): ${FULL_IMAGE}"
docker build --platform linux/amd64 -t "${FULL_IMAGE}" \
  "$(cd "$(dirname "$0")/../.." && pwd)"

echo "==> Authenticating with ECR"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

aws ecr describe-repositories \
  --repository-names libra_arcana \
  --region "${AWS_REGION}" > /dev/null 2>&1 \
  || aws ecr create-repository \
       --repository-name libra_arcana \
       --region "${AWS_REGION}"

echo "==> Pushing image"
docker push "${FULL_IMAGE}"

echo "==> Registering new task definition revision"
RENDERED=$(sed \
  -e "s|<ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g" \
  -e "s|<REGION>|${AWS_REGION}|g" \
  -e "s|<IMAGE_TAG>|${IMAGE_TAG}|g" \
  "${TASK_DEF_FILE}")

NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --region "${AWS_REGION}" \
  --cli-input-json "${RENDERED}" \
  --query "taskDefinition.taskDefinitionArn" \
  --output text)

echo "  Registered: ${NEW_TASK_DEF_ARN}"

echo "==> Updating ECS service"
aws ecs update-service \
  --region "${AWS_REGION}" \
  --cluster "${ECS_CLUSTER}" \
  --service "${ECS_SERVICE}" \
  --task-definition "${NEW_TASK_DEF_ARN}" \
  --force-new-deployment \
  --output text > /dev/null

echo "==> Waiting for service to stabilise..."
aws ecs wait services-stable \
  --region "${AWS_REGION}" \
  --cluster "${ECS_CLUSTER}" \
  --services "${ECS_SERVICE}"

echo "==> Deploy complete — ${FULL_IMAGE}"

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
# Base the new revision on the current running task def so credentials stay in
# ECS and never need to be in source. Just swap the app container's image.
CURRENT_TASK_DEF_ARN=$(aws ecs describe-services \
  --cluster "${ECS_CLUSTER}" \
  --services "${ECS_SERVICE}" \
  --region "${AWS_REGION}" \
  --query "services[0].taskDefinition" \
  --output text)

CURRENT_TASK_DEF=$(aws ecs describe-task-definition \
  --task-definition "${CURRENT_TASK_DEF_ARN}" \
  --region "${AWS_REGION}" \
  --query "taskDefinition" \
  --output json)

NEW_TASK_DEF_JSON=$(echo "${CURRENT_TASK_DEF}" \
  | jq --arg IMAGE "${FULL_IMAGE}" \
      'del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)
       | (.containerDefinitions[] | select(.name=="libra_arcana") | .image) |= $IMAGE')

NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --region "${AWS_REGION}" \
  --cli-input-json "${NEW_TASK_DEF_JSON}" \
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

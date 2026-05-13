#!/usr/bin/env bash
set -euo pipefail

# ─── Fill these in (must match deploy.sh) ────────────────────────────────────
AWS_REGION="us-east-2"
ECS_CLUSTER="default"
ECS_SERVICE="libra-arcana-web"
MIN_TASKS=1
MAX_TASKS=4
CPU_TARGET=70      # scale out when avg CPU exceeds this %
SCALE_OUT_COOLDOWN=60
SCALE_IN_COOLDOWN=300
# ─────────────────────────────────────────────────────────────────────────────

RESOURCE_ID="service/${ECS_CLUSTER}/${ECS_SERVICE}"

echo "==> Registering scalable target (${MIN_TASKS}–${MAX_TASKS} tasks)"
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id "${RESOURCE_ID}" \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity "${MIN_TASKS}" \
  --max-capacity "${MAX_TASKS}" \
  --region "${AWS_REGION}"

echo "==> Attaching CPU target-tracking policy (target: ${CPU_TARGET}%)"
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id "${RESOURCE_ID}" \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name libra-arcana-cpu-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration "{
    \"TargetValue\": ${CPU_TARGET}.0,
    \"PredefinedMetricSpecification\": {
      \"PredefinedMetricType\": \"ECSServiceAverageCPUUtilization\"
    },
    \"ScaleOutCooldown\": ${SCALE_OUT_COOLDOWN},
    \"ScaleInCooldown\": ${SCALE_IN_COOLDOWN}
  }" \
  --region "${AWS_REGION}"

echo "==> Autoscaling configured."
echo "    Tasks: ${MIN_TASKS}–${MAX_TASKS}"
echo "    Scale out at ${CPU_TARGET}% CPU, scale in cooldown ${SCALE_IN_COOLDOWN}s"

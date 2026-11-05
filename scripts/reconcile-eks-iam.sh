#!/usr/bin/env bash
set -euo pipefail
# Run from infra/terraform/envs/dev after terraform init.
CLUSTER_NAME="${CLUSTER_NAME:-buddu-ebooks}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
tracked() { terraform state list | grep -Fxq "$1"; }
verify_tags() {
  local tags="$1"
  jq -e 'any(.[]; .Key=="Project" and .Value=="cloudops-microservices-platform") and any(.[]; .Key=="Environment" and .Value=="dev") and any(.[]; .Key=="ManagedBy" and .Value=="Terraform")' <<<"$tags" >/dev/null || {
    echo "::error::Existing IAM resource lacks verified POC ownership tags; refusing import"; exit 1;
  }
}
role() {
  local addr="$1" name="$2" tags
  if tracked "$addr"; then echo "Tracked: $addr"; return; fi
  if ! aws iam get-role --role-name "$name" >/dev/null 2>&1; then echo "Absent: $name"; return; fi
  tags="$(aws iam list-role-tags --role-name "$name" --query Tags --output json)"
  verify_tags "$tags"
  terraform import -input=false -lock-timeout=5m "$addr" "$name"
}
policy() {
  local addr="$1" name="$2" arn tags
  arn="arn:aws:iam::${ACCOUNT_ID}:policy/${name}"
  if tracked "$addr"; then echo "Tracked: $addr"; return; fi
  if ! aws iam get-policy --policy-arn "$arn" >/dev/null 2>&1; then echo "Absent: $arn"; return; fi
  tags="$(aws iam list-policy-tags --policy-arn "$arn" --query Tags --output json)"
  verify_tags "$tags"
  terraform import -input=false -lock-timeout=5m "$addr" "$arn"
}
role aws_iam_role.node "${CLUSTER_NAME}-node-role"
role aws_iam_role.lab_admin "${CLUSTER_NAME}-lab-admin"
policy aws_iam_policy.lbc "${CLUSTER_NAME}-aws-load-balancer-controller"
echo "IAM recovery complete. Review a Terraform plan before applying."

#!/usr/bin/env bash
set -euo pipefail

registry="${REGISTRY:?Set REGISTRY, for example docker.io/your-user or ACCOUNT.dkr.ecr.REGION.amazonaws.com}"
tag="${IMAGE_TAG:-0.1-dev}"
services=(gateway web auth catalog cart orders learning labs community certificates leaderboard)

for service in "${services[@]}"; do
  image="${registry}/cloudops-${service}:${tag}"
  echo "Building ${image}"
  docker build -t "${image}" -f "services/${service}/Dockerfile" .
  docker push "${image}"
done

echo "Published ${#services[@]} images with tag ${tag}."

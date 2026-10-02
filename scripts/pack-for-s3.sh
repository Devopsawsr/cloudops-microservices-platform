#!/bin/sh
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-$ROOT/../cloud-and-devops-microservice.zip}"
cd "$ROOT/.."
rm -f "$DEST"
zip -r "$DEST" microservice \
  -x 'microservice/**/.DS_Store' \
  -x 'microservice/**/__pycache__/*' \
  -x 'microservice/data/*.json'
ls -lh "$DEST"
echo "Upload this zip in AWS Console → S3."

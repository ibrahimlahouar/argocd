#!/bin/bash
set -e

HARBOR="10.10.0.101:30500"
PROJECT="data-platform"
PLATFORM="linux/amd64"

echo "=== Pushing linux/amd64 images to Harbor ==="

# Function to mirror image
mirror() {
    local src=$1
    local dest=$2
    echo ">>> Mirroring $src -> $HARBOR/$PROJECT/$dest"
    docker pull --platform $PLATFORM "$src" || { echo "SKIP: Cannot pull $src"; return; }
    docker tag "$src" "$HARBOR/$PROJECT/$dest"
    docker push "$HARBOR/$PROJECT/$dest"
    echo "✓ Done: $dest"
}

# OpenMetadata and dependencies
mirror "docker.getcollate.io/openmetadata/server:1.11.2" "openmetadata-server:1.11.2"
mirror "apache/airflow:2.7.3-python3.10" "airflow:2.7.3-python3.10"
mirror "public.ecr.aws/bitnami/mysql:8.0.32" "mysql:8.0.32"
mirror "opensearchproject/opensearch:2.19.3" "opensearch:2.19.3"
mirror "busybox:latest" "busybox:latest"
mirror "curlimages/curl:latest" "curl:latest"

# Headlamp
mirror "ghcr.io/headlamp-k8s/headlamp:v0.24.1" "headlamp:v0.24.1"

# Vault
mirror "hashicorp/vault:1.15.2" "vault:1.15.2"

# Redis (for Airflow)
mirror "redis:7.0.11-alpine" "redis:7.0.11-alpine"

echo ""
echo "=== All images pushed to Harbor ==="

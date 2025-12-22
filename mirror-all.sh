#!/bin/bash

# Configuration
HARBOR_URL="10.10.0.101:30500"
PROJECT="data-platform"
HARBOR_USER="admin"
HARBOR_PASS="Harbor123!"

# Authenticate to Harbor
echo "Logging into Harbor at $HARBOR_URL..."
echo "$HARBOR_PASS" | docker login "$HARBOR_URL" -u "$HARBOR_USER" --password-stdin

# List of images to mirror: "SourceImage" "TargetNameInHarbor" "Tag"
IMAGES=(
    "minio/minio:latest" "minio" "latest"
    "minio/mc:latest" "mc" "latest"
    "ghcr.io/googlecloudplatform/spark-operator:v1beta2-1.3.8-3.1.1" "spark-operator" "v1beta2-1.3.8-3.1.1"
    "trinodb/trino:432" "trino" "432"
    "hashicorp/vault:1.15.2" "vault" "1.15.2"
    "hashicorp/vault-k8s:1.3.1" "vault-k8s" "1.3.1"
    "apache/airflow:2.7.3-python3.10" "airflow" "2.7.3-python3.10"
    "docker.getcollate.io/openmetadata/server:1.11.2" "openmetadata-server" "1.11.2"
    "docker.io/bitnamilegacy/mysql:8.0.37-debian-12-r2" "mysql" "8.0.37-debian-12-r2"
    "opensearchproject/opensearch:2.19.3" "opensearch" "2.19.3"
    "ghcr.io/headlamp-k8s/headlamp:v0.24.1" "headlamp" "v0.24.1"
    
    # Harbor internal components
    "goharbor/nginx-photon:v2.10.0" "nginx-photon" "v2.10.0"
    "goharbor/harbor-portal:v2.10.0" "harbor-portal" "v2.10.0"
    "goharbor/harbor-core:v2.10.0" "harbor-core" "v2.10.0"
    "goharbor/harbor-jobservice:v2.10.0" "harbor-jobservice" "v2.10.0"
    "goharbor/registry-photon:v2.10.0" "registry-photon" "v2.10.0"
    "goharbor/harbor-registryctl:v2.10.0" "harbor-registryctl" "v2.10.0"
    "goharbor/trivy-adapter-photon:v2.10.0" "trivy-adapter-photon" "v2.10.0"
    "goharbor/harbor-db:v2.10.0" "harbor-db" "v2.10.0"
    "goharbor/redis-photon:v2.10.0" "redis-photon" "v2.10.0"
    "goharbor/harbor-exporter:v2.10.0" "harbor-exporter" "v2.10.0"
)

echo "Starting mirroring process..."

for ((i=0; i<${#IMAGES[@]}; i+=3)); do
    SOURCE="${IMAGES[i]}"
    TARGET_NAME="${IMAGES[i+1]}"
    TAG="${IMAGES[i+2]}"
    TARGET_FULL="$HARBOR_URL/$PROJECT/$TARGET_NAME:$TAG"
    
    echo "---------------------------------------------------"
    echo "Mirroring: $SOURCE -> $TARGET_FULL"
    
    docker pull "$SOURCE"
    if [ $? -eq 0 ]; then
        docker tag "$SOURCE" "$TARGET_FULL"
        docker push "$TARGET_FULL"
        echo "✅ Successfully mirrored $TARGET_NAME"
    else
        echo "❌ Failed to pull $SOURCE"
    fi
done

echo "Mirroring process complete!"


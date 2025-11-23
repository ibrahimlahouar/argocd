#!/bin/bash
# scripts/mirror-images.sh
# Mirror Docker images to Harbor via bastion

set -e

HARBOR="10.10.0.101:30500"
PROJECT="data-platform"
BASTION="root@135.181.211.227"
SSH_KEY="~/.ssh/id_ed25519"

echo "🐳 Harbor Image Mirroring Script (via Bastion)"
echo "================================================"
echo ""

# Array of images to mirror
# Format: "source_image:tag|target_name:tag"
IMAGES=(
    "ghcr.io/headlamp-k8s/headlamp:v0.21.0|headlamp:v0.21.0"
    "trinodb/trino:435|trino:435"
    "hashicorp/vault:1.15.0|vault:1.15.0"
    "ghcr.io/kubeflow/spark-operator:v1beta2-1.3.8-3.1.1|spark-operator:v1beta2-1.3.8-3.1.1"
)

echo "📦 Images to mirror:"
for mapping in "${IMAGES[@]}"; do
    source=$(echo $mapping | cut -d'|' -f1)
    echo "  - $source"
done
echo ""

# Mirror each image via bastion
for mapping in "${IMAGES[@]}"; do
    source=$(echo $mapping | cut -d'|' -f1)
    target_name=$(echo $mapping | cut -d'|' -f2)
    target="$HARBOR/$PROJECT/$target_name"
    
    echo "========================================="
    echo "📥 Processing: $source"
    echo ""
    
    # Pull image locally
    echo "  [1/3] Pulling image locally..."
    docker pull $source
    
    # Save image to tarball
    image_file="/tmp/$(echo $source | tr '/:' '_').tar"
    echo "  [2/3] Saving to $image_file..."
    docker save $source -o $image_file
    
    # Transfer to bastion and push to Harbor
    echo "  [3/3] Transferring and pushing to Harbor..."
    cat $image_file | ssh -i $SSH_KEY $BASTION "cat > /tmp/image.tar && \
docker login $HARBOR -u admin -p Harbor123! && \
docker load -i /tmp/image.tar && \
docker tag $source $target && \
docker push $target && \
rm -f /tmp/image.tar"
    
    # Cleanup local tarball
    rm -f $image_file
    
    echo "  ✅ Mirrored: $source -> $target"
done

echo ""
echo "=========================================="
echo "✨ All images successfully mirrored!"
echo "=========================================="


#!/bin/bash
# Script pour pusher les images MinIO sur Harbor
# Date: 23 Novembre 2025

set -e

# Configuration
HARBOR_REGISTRY="10.10.0.101:30500"
HARBOR_PROJECT="data-platform"
HARBOR_USER="admin"
HARBOR_PASSWORD="Harbor123!"

# Images à pusher
MINIO_VERSION="RELEASE.2024-12-18T13-15-44Z"
MC_VERSION="RELEASE.2024-11-21T17-21-54Z"

echo "🚀 Push des images MinIO vers Harbor"
echo "======================================"
echo ""

# Login Harbor
echo "📝 Login sur Harbor ($HARBOR_REGISTRY)..."
echo "$HARBOR_PASSWORD" | docker login "$HARBOR_REGISTRY" -u "$HARBOR_USER" --password-stdin

echo ""
echo "📦 Traitement de l'image MinIO..."
echo "-----------------------------------"

# Pull MinIO
echo "1️⃣ Pull de minio/minio:$MINIO_VERSION..."
docker pull "minio/minio:$MINIO_VERSION"

# Tag MinIO
echo "2️⃣ Tag pour Harbor..."
docker tag "minio/minio:$MINIO_VERSION" \
  "$HARBOR_REGISTRY/$HARBOR_PROJECT/minio:$MINIO_VERSION"

# Push MinIO
echo "3️⃣ Push vers Harbor..."
docker push "$HARBOR_REGISTRY/$HARBOR_PROJECT/minio:$MINIO_VERSION"

echo "✅ MinIO image pushée avec succès!"
echo ""

echo "📦 Traitement de l'image MinIO Client (mc)..."
echo "----------------------------------------------"

# Pull MC
echo "1️⃣ Pull de minio/mc:$MC_VERSION..."
docker pull "minio/mc:$MC_VERSION"

# Tag MC
echo "2️⃣ Tag pour Harbor..."
docker tag "minio/mc:$MC_VERSION" \
  "$HARBOR_REGISTRY/$HARBOR_PROJECT/mc:$MC_VERSION"

# Push MC
echo "3️⃣ Push vers Harbor..."
docker push "$HARBOR_REGISTRY/$HARBOR_PROJECT/mc:$MC_VERSION"

echo "✅ MinIO Client (mc) image pushée avec succès!"
echo ""

echo "🎉 Toutes les images ont été pushées avec succès!"
echo ""
echo "📋 Vérification:"
echo "----------------"
echo "MinIO: $HARBOR_REGISTRY/$HARBOR_PROJECT/minio:$MINIO_VERSION"
echo "MC:    $HARBOR_REGISTRY/$HARBOR_PROJECT/mc:$MC_VERSION"
echo ""
echo "Vous pouvez vérifier sur Harbor: http://$HARBOR_REGISTRY"
echo ""
echo "🚀 Prochaine étape: Sync Argo CD"
echo "argocd app sync minio"


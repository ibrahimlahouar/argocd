#!/bin/bash

# Script de backup des configurations Helm
# Usage: ./backup.sh [output-dir]

set -e

OUTPUT_DIR=${1:-"./backups/$(date +%Y%m%d_%H%M%S)"}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "💾 Backup des configurations Helm"
echo "Destination: $OUTPUT_DIR"
echo "============================================================="

# Créer le répertoire de backup
mkdir -p "$OUTPUT_DIR"

# Liste des namespaces à sauvegarder
NAMESPACES="minio vault spark-operator harbor headlamp trino"

for ns in $NAMESPACES; do
    echo ""
    echo "📦 Backup du namespace: $ns"
    
    # Créer le dossier pour le namespace
    NS_DIR="$OUTPUT_DIR/$ns"
    mkdir -p "$NS_DIR"
    
    # Backup des releases Helm
    echo "  → Helm releases"
    helm list -n $ns -o yaml > "$NS_DIR/helm-releases.yaml" 2>/dev/null || echo "  ⚠️  Aucune release Helm"
    
    # Backup des values
    for release in $(helm list -n $ns -q 2>/dev/null); do
        echo "  → Values de $release"
        helm get values $release -n $ns > "$NS_DIR/${release}-values.yaml" 2>/dev/null || true
    done
    
    # Backup des ressources K8s
    echo "  → ConfigMaps"
    kubectl get configmaps -n $ns -o yaml > "$NS_DIR/configmaps.yaml" 2>/dev/null || true
    
    echo "  → Secrets (metadata seulement)"
    kubectl get secrets -n $ns -o yaml | \
        sed 's/^\([[:space:]]*data:\).*/\1 <REDACTED>/' > "$NS_DIR/secrets-metadata.yaml" 2>/dev/null || true
    
    echo "  → Services"
    kubectl get svc -n $ns -o yaml > "$NS_DIR/services.yaml" 2>/dev/null || true
    
    echo "  → PersistentVolumeClaims"
    kubectl get pvc -n $ns -o yaml > "$NS_DIR/pvcs.yaml" 2>/dev/null || true
    
    echo "  ✅ Backup de $ns terminé"
done

# Backup des ClusterRoleBindings pour Spark
echo ""
echo "📦 Backup des ressources cluster-wide"
kubectl get clusterrolebinding -o yaml | \
    grep -A 50 "spark" > "$OUTPUT_DIR/cluster-rolebindings.yaml" 2>/dev/null || true

# Créer un résumé
cat > "$OUTPUT_DIR/README.md" <<EOF
# Backup Data Platform

**Date**: $(date)
**Cluster**: $(kubectl config current-context)

## Namespaces sauvegardés

EOF

for ns in $NAMESPACES; do
    echo "- $ns" >> "$OUTPUT_DIR/README.md"
done

cat >> "$OUTPUT_DIR/README.md" <<EOF

## Restauration

La restauration recommandée consiste à réappliquer la configuration GitOps (ArgoCD)
et à laisser ArgoCD resynchroniser les applications (MinIO, registry, etc.).

\`\`\`bash
# Exemple: re-déployer la plateforme complète
kubectl apply -n argocd -f root-app.yaml
\`\`\`

## Fichiers

- \`<namespace>/helm-releases.yaml\`: Liste des releases Helm
- \`<namespace>/<release>-values.yaml\`: Values Helm de chaque release
- \`<namespace>/configmaps.yaml\`: ConfigMaps
- \`<namespace>/secrets-metadata.yaml\`: Metadata des secrets (pas les données)
- \`<namespace>/services.yaml\`: Services
- \`<namespace>/pvcs.yaml\`: PersistentVolumeClaims
EOF

# Compresser le backup
echo ""
echo "📦 Compression du backup..."
tar -czf "$OUTPUT_DIR.tar.gz" -C "$(dirname $OUTPUT_DIR)" "$(basename $OUTPUT_DIR)"

echo ""
echo "============================================================="
echo "✅ Backup terminé !"
echo ""
echo "📁 Fichiers:"
echo "  - Dossier: $OUTPUT_DIR"
echo "  - Archive: $OUTPUT_DIR.tar.gz"
echo ""
echo "Taille: $(du -sh $OUTPUT_DIR.tar.gz | cut -f1)"

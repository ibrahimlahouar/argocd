#!/bin/bash

# Script historique de déploiement de tous les services via charts locaux Helm.
# ⚠️ Aujourd'hui, la plateforme est gérée en GitOps via ArgoCD (voir root-app.yaml).
# Usage recommandé: appliquer root-app.yaml plutôt que ce script.
# Usage: ./deploy-all.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CHARTS_DIR="$SCRIPT_DIR/../charts"

echo "🚀 Déploiement de la Data Platform (environnement: $ENVIRONMENT)"
echo "============================================================="

# Fonction pour déployer un chart
deploy_chart() {
    local name=$1
    local namespace=$2
    local chart_dir="$CHARTS_DIR/$name"
    local values_file="values-${ENVIRONMENT}.yaml"
    
    echo ""
    echo "📦 Déploiement de $name..."
    
    # Vérifier si le chart existe
    if [ ! -d "$chart_dir" ]; then
        echo "⚠️  Chart $name introuvable dans $chart_dir"
        return 1
    fi
    
    # Créer le namespace si nécessaire
    kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -
    
    # Utiliser values-dev.yaml ou values.yaml
    if [ -f "$chart_dir/$values_file" ]; then
        VALUES_ARG="-f $chart_dir/$values_file"
    elif [ -f "$chart_dir/values.yaml" ]; then
        VALUES_ARG="-f $chart_dir/values.yaml"
    else
        VALUES_ARG=""
    fi
    
    # Installer ou upgrader le chart
    if helm list -n $namespace | grep -q "^$name"; then
        echo "  ↻ Upgrade de $name..."
        helm upgrade $name $chart_dir -n $namespace $VALUES_ARG
    else
        echo "  + Installation de $name..."
        helm install $name $chart_dir -n $namespace --create-namespace $VALUES_ARG
    fi
    
    echo "  ✅ $name déployé"
}

# Déployer dans l'ordre (dépendances d'abord)

# 1. Stockage (déployé maintenant via ArgoCD, laissé ici pour compatibilité éventuelle)
# deploy_chart "minio" "minio"

# 2. Sécurité
deploy_chart "vault" "vault"

# 3. Registry (déployé maintenant via ArgoCD sous forme de manifests)
# deploy_chart "docker-registry" "harbor"

# 4. Compute
deploy_chart "spark-operator" "spark-operator"
deploy_chart "trino" "trino"

# 5. UI
deploy_chart "headlamp" "headlamp"

# Vérifier que tout est déployé
echo ""
echo "============================================================="
echo "📊 Status des déploiements:"
echo ""

helm list --all-namespaces | grep -E "minio|vault|harbor|spark|trino|headlamp"

echo ""
echo "============================================================="
echo "✅ Déploiement terminé !"
echo ""
echo "Pour vérifier les pods:"
echo "  kubectl get pods --all-namespaces"
echo ""
echo "Pour accéder aux services, démarrez les tunnels SSH:"
echo "  cd $SCRIPT_DIR/.."
echo "  ./tunnels.sh start"

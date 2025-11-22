#!/bin/bash

# Script de mise à jour d'un chart Helm
# Usage: ./update-chart.sh <chart-name> [environment]

set -e

CHART_NAME=$1
ENVIRONMENT=${2:-dev}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CHART_DIR="$SCRIPT_DIR/../charts/$CHART_NAME"

if [ -z "$CHART_NAME" ]; then
    echo "Usage: ./update-chart.sh <chart-name> [environment]"
    echo ""
    echo "Charts disponibles:"
    ls -1 "$SCRIPT_DIR/../charts/"
    exit 1
fi

if [ ! -d "$CHART_DIR" ]; then
    echo "❌ Chart $CHART_NAME introuvable"
    exit 1
fi

# Mapper le nom du chart au namespace
case $CHART_NAME in
    minio)
        NAMESPACE="minio"
        ;;
    vault)
        NAMESPACE="vault"
        ;;
    spark-operator)
        NAMESPACE="spark-operator"
        ;;
    docker-registry)
        NAMESPACE="harbor"
        ;;
    headlamp)
        NAMESPACE="headlamp"
        ;;
    trino)
        NAMESPACE="trino"
        ;;
    *)
        NAMESPACE="$CHART_NAME"
        ;;
esac

echo "🔄 Mise à jour de $CHART_NAME (namespace: $NAMESPACE, env: $ENVIRONMENT)"

# Déterminer le fichier values
VALUES_FILE="values-${ENVIRONMENT}.yaml"
if [ -f "$CHART_DIR/$VALUES_FILE" ]; then
    VALUES_ARG="-f $CHART_DIR/$VALUES_FILE"
elif [ -f "$CHART_DIR/values.yaml" ]; then
    VALUES_ARG="-f $CHART_DIR/values.yaml"
else
    VALUES_ARG=""
fi

# Dry-run pour voir les changements
echo ""
echo "📋 Changements à appliquer (dry-run):"
helm diff upgrade $CHART_NAME $CHART_DIR -n $NAMESPACE $VALUES_ARG || true

# Demander confirmation
echo ""
read -p "Continuer avec la mise à jour ? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Annulé"
    exit 1
fi

# Appliquer la mise à jour
echo ""
echo "⚙️  Application de la mise à jour..."
helm upgrade $CHART_NAME $CHART_DIR -n $NAMESPACE $VALUES_ARG

echo ""
echo "✅ Mise à jour terminée !"
echo ""
echo "Vérifier le status:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  helm status $CHART_NAME -n $NAMESPACE"

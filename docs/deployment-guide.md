# 📖 Guide de Déploiement - Data Platform

Ce guide explique comment déployer la plateforme de données sur Kubernetes.

## 🎯 Prérequis

### Infrastructure

- Cluster Kubernetes 1.24+
- kubectl configuré et accès au cluster
- Helm 3.x installé
- Accès administrateur au cluster

### Stockage

- StorageClass disponible (longhorn, local-path, etc.)
- Minimum 1 To d'espace disque disponible

### Réseau

- Accès aux NodePorts (30000-32767)
- Ou Ingress Controller configuré

## 🚀 Installation Rapide

### Option 1: Déploiement Automatique

```bash
cd /Users/ilahouar/Documents/proxmox/data-platform

# Déployer tous les services (environnement dev)
./scripts/deploy-all.sh dev

# Ou en production
./scripts/deploy-all.sh prod
```

### Option 2: Déploiement Manuel

#### 1. Ajouter les repositories Helm

```bash
# MinIO
helm repo add bitnami https://charts.bitnami.com/bitnami

# Vault
helm repo add hashicorp https://helm.releases.hashicorp.com

# Spark Operator
helm repo add spark-operator https://kubeflow.github.io/spark-operator

# Docker Registry
helm repo add twuni https://helm.twun.io

# Headlamp
helm repo add headlamp https://headlamp-k8s.github.io/headlamp/

# Trino
helm repo add trino https://trinodb.github.io/charts

# Mettre à jour
helm repo update
```

#### 2. Déployer dans l'ordre

##### a) MinIO (Stockage S3)

```bash
kubectl create namespace minio

helm install minio bitnami/minio \
  --namespace minio \
  --values charts/minio/values.yaml

# Vérifier
kubectl get pods -n minio
kubectl get svc -n minio
```

##### b) Vault (Secrets)

```bash
kubectl create namespace vault

helm install vault hashicorp/vault \
  --namespace vault \
  --values charts/vault/values.yaml

# Vérifier
kubectl get pods -n vault
```

##### c) Docker Registry

```bash
kubectl create namespace harbor

helm install docker-registry twuni/docker-registry \
  --namespace harbor \
  --values charts/docker-registry/values.yaml

# Vérifier
kubectl get pods -n harbor
```

##### d) Spark Operator

```bash
kubectl create namespace spark-operator
kubectl create namespace spark

helm install spark-operator spark-operator/spark-operator \
  --namespace spark-operator \
  --values charts/spark-operator/values.yaml

# Créer ServiceAccount pour les jobs
kubectl create serviceaccount spark -n spark
kubectl create clusterrolebinding spark-role \
  --clusterrole=edit \
  --serviceaccount=spark:spark

# Vérifier
kubectl get pods -n spark-operator
```

##### e) Trino (SQL Engine)

```bash
kubectl create namespace trino

helm install trino trino/trino \
  --namespace trino \
  --values charts/trino/values.yaml

# Vérifier
kubectl get pods -n trino
```

##### f) Headlamp (K8s UI)

```bash
kubectl create namespace headlamp

helm install headlamp headlamp/headlamp \
  --namespace headlamp \
  --values charts/headlamp/values.yaml

# Créer le token d'accès
kubectl create serviceaccount headlamp-admin -n headlamp
kubectl create clusterrolebinding headlamp-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=headlamp:headlamp-admin

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: headlamp-admin-token
  namespace: headlamp
  annotations:
    kubernetes.io/service-account.name: headlamp-admin
type: kubernetes.io/service-account-token
EOF

# Récupérer le token
kubectl get secret headlamp-admin-token -n headlamp \
  -o jsonpath='{.data.token}' | base64 -d > headlamp-token.txt

# Vérifier
kubectl get pods -n headlamp
```

## 🔧 Post-Installation

### Créer les buckets MinIO

```bash
# Méthode 1: Via UI
# Ouvrir http://localhost:9001 et créer manuellement

# Méthode 2: Via mc CLI
mc alias set myminio http://10.10.0.101:30900 minioadmin minioadmin123
mc mb myminio/warehouse
mc mb myminio/datalake
mc mb myminio/airflow
mc mb myminio/harbor
```

### Configurer Vault

```bash
# Créer les secrets MinIO
kubectl exec -n vault vault-0 -- \
  vault kv put secret/minio \
    access_key=minioadmin \
    secret_key=minioadmin123 \
    endpoint=http://minio.minio.svc:9000
```

### Configurer Docker pour le Registry

```bash
# Ajouter dans Docker Desktop → Settings → Docker Engine
{
  "insecure-registries": [
    "10.10.0.101:30500",
    "localhost:5050"
  ]
}
```

### Configurer les tunnels SSH

```bash
ssh -N -f \
  -L 8080:10.10.0.101:30098 \
  -L 9001:10.10.0.101:30901 \
  -L 9000:10.10.0.101:30900 \
  -L 8200:10.10.0.101:30820 \
  -L 5050:10.10.0.101:30500 \
  -i ~/.ssh/id_ed25519 \
  root@135.181.211.227
```

## ✅ Vérification

### Vérifier tous les pods

```bash
kubectl get pods --all-namespaces | grep -E "minio|vault|spark|harbor|headlamp|trino"
```

Tous les pods doivent être en état `Running`.

### Tester les accès

```bash
# MinIO
curl http://10.10.0.101:30900/minio/health/live

# Vault
curl http://10.10.0.101:30820/v1/sys/health

# Registry
curl http://10.10.0.101:30500/v2/_catalog

# Headlamp (via navigateur)
# http://localhost:8080
```

### Tester un job Spark

```bash
kubectl apply -f - <<EOF
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: spark-pi
  namespace: spark
spec:
  type: Scala
  mode: cluster
  image: "apache/spark:v3.5.0"
  mainClass: org.apache.spark.examples.SparkPi
  mainApplicationFile: "local:///opt/spark/examples/jars/spark-examples_2.12-3.5.0.jar"
  sparkVersion: "3.5.0"
  driver:
    cores: 1
    memory: "1g"
    serviceAccount: spark
  executor:
    cores: 1
    instances: 2
    memory: "1g"
EOF

# Vérifier
kubectl get sparkapplications -n spark
kubectl logs -n spark spark-pi-driver
```

## 🔄 Mise à Jour

### Mettre à jour un service

```bash
# Avec le script
./scripts/update-chart.sh minio prod

# Ou manuellement
helm upgrade minio bitnami/minio \
  -n minio \
  --values charts/minio/values.yaml
```

### Mettre à jour tous les services

```bash
# Redéployer tout
./scripts/deploy-all.sh prod
```

## 💾 Backup

### Créer un backup

```bash
./scripts/backup.sh ./backups/$(date +%Y%m%d)
```

### Restaurer depuis un backup

```bash
# Exemple pour MinIO
kubectl create namespace minio
helm install minio bitnami/minio \
  -n minio \
  -f backups/20251121/minio/minio-values.yaml
```

## 🐛 Troubleshooting

Voir le guide complet : [docs/troubleshooting.md](./troubleshooting.md)

### Problèmes fréquents

#### Pod en CrashLoopBackOff

```bash
kubectl logs <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

#### PVC en Pending

```bash
# Vérifier la StorageClass
kubectl get storageclass

# Vérifier le provisioner
kubectl get pods -n kube-system | grep provisioner
```

#### Service inaccessible

```bash
# Vérifier le service
kubectl get svc -n <namespace>

# Vérifier les endpoints
kubectl get endpoints -n <namespace>
```

## 📚 Documentation

- [Architecture](./architecture.md)
- [Troubleshooting](./troubleshooting.md)
- Charts individuels dans `charts/*/README.md`

## 🎯 Prochaines Étapes

Après déploiement réussi :

1. Déployer Airflow pour l'orchestration
2. Déployer Superset pour la visualisation
3. Configurer le monitoring (Prometheus + Grafana)
4. Mettre en place les backups automatiques
5. Configurer TLS/HTTPS
6. Durcir la sécurité (RBAC, Network Policies)

---

**Dernière mise à jour**: 2025-11-21

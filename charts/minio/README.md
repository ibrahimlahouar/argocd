# 🗄️ MinIO - Stockage S3

MinIO est un stockage d'objets S3-compatible haute performance déployé sur Kubernetes.

## 📋 Informations

- **Namespace**: `minio`
- **Chart Source**: `bitnami/minio` ou custom
- **Version**: Latest stable
- **Storage Class**: `local-path` ou `longhorn`

## 🎯 Configuration

### Accès

- **API Endpoint**: `http://10.10.0.101:30900`
- **Console UI**: `http://10.10.0.101:30901`
  - Username: `minioadmin`
  - Password: `minioadmin123`

### Ports

- **Port API**: 30900 (NodePort)
- **Port Console**: 30901 (NodePort)

## 📦 Buckets Créés

```
warehouse/    → Tables Apache Iceberg
datalake/     → Données brutes (raw data)
airflow/      → Logs et DAGs Airflow
harbor/       → Images Docker Registry
```

## 🚀 Installation

### Via Helm (Bitnami)

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm install minio bitnami/minio \
  --namespace minio \
  --create-namespace \
  --values values.yaml
```

### Via kubectl (Custom)

```bash
kubectl apply -f minio-deployment.yaml -n minio
```

## ⚙️ Configuration values.yaml

```yaml
auth:
  rootUser: minioadmin
  rootPassword: minioadmin123

mode: standalone  # ou distributed pour HA

persistence:
  enabled: true
  size: 500Gi
  storageClass: longhorn

service:
  type: NodePort
  ports:
    api: 30900
    console: 30901

resources:
  requests:
    memory: 2Gi
    cpu: 1000m
  limits:
    memory: 4Gi
    cpu: 2000m

# Buckets à créer automatiquement
defaultBuckets: "warehouse,datalake,airflow,harbor"
```

## 🔧 Utilisation

### Dans Spark

```python
spark.conf.set("spark.hadoop.fs.s3a.endpoint", "http://minio.minio.svc:9000")
spark.conf.set("spark.hadoop.fs.s3a.access.key", "minioadmin")
spark.conf.set("spark.hadoop.fs.s3a.secret.key", "minioadmin123")
spark.conf.set("spark.hadoop.fs.s3a.path.style.access", "true")
spark.conf.set("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")

# Lire/écrire
df = spark.read.parquet("s3a://datalake/data.parquet")
df.write.parquet("s3a://warehouse/output.parquet")
```

### Avec AWS CLI

```bash
# Configurer AWS CLI
export AWS_ACCESS_KEY_ID=minioadmin
export AWS_SECRET_ACCESS_KEY=minioadmin123
export AWS_ENDPOINT_URL=http://10.10.0.101:30900

# Lister les buckets
aws s3 ls --endpoint-url $AWS_ENDPOINT_URL

# Upload un fichier
aws s3 cp data.csv s3://datalake/ --endpoint-url $AWS_ENDPOINT_URL

# Télécharger un fichier
aws s3 cp s3://datalake/data.csv ./ --endpoint-url $AWS_ENDPOINT_URL
```

### Avec mc (MinIO Client)

```bash
# Installer mc
brew install minio/stable/mc

# Configurer alias
mc alias set myminio http://10.10.0.101:30900 minioadmin minioadmin123

# Lister buckets
mc ls myminio

# Upload
mc cp data.csv myminio/datalake/

# Mirror un dossier
mc mirror ./local-folder myminio/datalake/folder/
```

## 🐛 Troubleshooting

### Pod ne démarre pas

```bash
# Vérifier les logs
kubectl logs -n minio -l app=minio

# Vérifier le PVC
kubectl get pvc -n minio

# Décrire le pod
kubectl describe pod -n minio -l app=minio
```

### Erreur de connexion

```bash
# Vérifier le service
kubectl get svc -n minio

# Tester depuis un pod
kubectl run -it --rm test --image=busybox -n minio -- sh
wget -O- http://minio:9000/minio/health/live
```

### Performance lente

- Vérifier les ressources CPU/RAM
- Considérer le mode `distributed` pour plus de performance
- Vérifier la classe de stockage (préférer des disques SSD)

## 📊 Monitoring

### Métriques disponibles

MinIO expose des métriques Prometheus sur `/minio/v2/metrics/cluster`

```bash
# Accéder aux métriques
curl http://10.10.0.101:30900/minio/v2/metrics/cluster
```

### Dashboard Grafana recommandé

- MinIO Dashboard (ID: 13502)

## 🔐 Sécurité

### Mode Production

Pour la production, modifier :

```yaml
auth:
  rootUser: <strong-username>
  rootPassword: <strong-password-32-chars>

# Activer TLS
tls:
  enabled: true
  certSecret: minio-tls

# Network policies
networkPolicy:
  enabled: true
  allowExternal: false
```

### Créer des utilisateurs supplémentaires

```bash
# Via mc
mc admin user add myminio readonly readonly123

# Créer une policy
mc admin policy create myminio readonly-policy policy.json
mc admin policy attach myminio readonly-policy --user readonly
```

## 📝 CHANGELOG

### 2025-11-21
- ✅ Déploiement initial
- ✅ Création des buckets: warehouse, datalake, airflow, harbor
- ✅ Configuration NodePort 30900/30901

---

**Maintainer**: Data Platform Team  
**Last Updated**: 2025-11-21

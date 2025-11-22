# ⚡ Spark Operator - Compute Engine

Spark Operator permet d'exécuter des jobs Apache Spark nativement sur Kubernetes.

## 📋 Informations

- **Namespace Operator**: `spark-operator`
- **Namespace Jobs**: `spark`
- **Chart Source**: `spark-operator/spark-operator`
- **Version**: 1.x

## 🚀 Installation

```bash
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update

helm install spark-operator spark-operator/spark-operator \
  --namespace spark-operator \
  --create-namespace \
  --values values.yaml

# Créer le namespace pour les jobs
kubectl create namespace spark
```

## ⚙️ Configuration values.yaml

```yaml
sparkJobNamespace: spark

webhook:
  enable: true
  port: 8080

resources:
  limits:
    cpu: 200m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi

# Activer le webhook pour validation
webhook:
  enable: true
```

## 🔧 Créer un Job Spark

### Exemple Simple

```yaml
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: spark-pi
  namespace: spark
spec:
  type: Scala
  mode: cluster
  image: "apache/spark:v3.5.0"
  imagePullPolicy: IfNotPresent
  mainClass: org.apache.spark.examples.SparkPi
  mainApplicationFile: "local:///opt/spark/examples/jars/spark-examples_2.12-3.5.0.jar"
  sparkVersion: "3.5.0"
  
  driver:
    cores: 1
    memory: "1g"
    serviceAccount: spark
    labels:
      version: "3.5.0"
  
  executor:
    cores: 1
    instances: 2
    memory: "1g"
    labels:
      version: "3.5.0"
```

### Exemple PySpark avec MinIO

```yaml
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: pyspark-minio
  namespace: spark
spec:
  type: Python
  pythonVersion: "3"
  mode: cluster
  image: "apache/spark-py:v3.5.0"
  imagePullPolicy: IfNotPresent
  mainApplicationFile: "s3a://datalake/jobs/myjob.py"
  sparkVersion: "3.5.0"
  
  hadoopConf:
    "fs.s3a.endpoint": "http://minio.minio.svc:9000"
    "fs.s3a.access.key": "minioadmin"
    "fs.s3a.secret.key": "minioadmin123"
    "fs.s3a.path.style.access": "true"
    "fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
  
  sparkConf:
    "spark.sql.catalog.iceberg": "org.apache.iceberg.spark.SparkCatalog"
    "spark.sql.catalog.iceberg.type": "hadoop"
    "spark.sql.catalog.iceberg.warehouse": "s3a://warehouse/"
  
  driver:
    cores: 1
    memory: "2g"
    serviceAccount: spark
    env:
    - name: AWS_REGION
      value: us-east-1
  
  executor:
    cores: 2
    instances: 3
    memory: "4g"
```

## 📦 Déployer un Job

```bash
# Appliquer le manifest
kubectl apply -f spark-job.yaml

# Vérifier le status
kubectl get sparkapplications -n spark

# Voir les logs du driver
kubectl logs -n spark spark-pi-driver -f

# Supprimer le job
kubectl delete sparkapplication spark-pi -n spark
```

## 🔧 Commandes Utiles

```bash
# Lister tous les jobs Spark
kubectl get sparkapplications -n spark

# Détails d'un job
kubectl describe sparkapplication spark-pi -n spark

# Logs du driver
POD=$(kubectl get pods -n spark -l spark-role=driver -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n spark $POD -f

# Logs des executors
kubectl logs -n spark -l spark-role=executor

# Shell interactif dans le driver
kubectl exec -it -n spark $POD -- bash
```

## 🎯 Exemple de Pipeline

### Script Python (myjob.py)

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("MyDataPipeline") \
    .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog") \
    .getOrCreate()

# Lire depuis MinIO
df = spark.read.parquet("s3a://datalake/input/data.parquet")

# Transformation
result = df.filter(df.age > 18).groupBy("country").count()

# Écrire dans Iceberg
result.writeTo("iceberg.analytics.user_stats") \
    .using("iceberg") \
    .partitionedBy("country") \
    .createOrReplace()

spark.stop()
```

### Lancer le job

```bash
kubectl apply -f - <<EOF
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: data-pipeline
  namespace: spark
spec:
  type: Python
  pythonVersion: "3"
  mode: cluster
  image: "apache/spark-py:v3.5.0"
  mainApplicationFile: "s3a://datalake/jobs/myjob.py"
  sparkVersion: "3.5.0"
  # ... reste de la config
EOF
```

## 🐛 Troubleshooting

### Job ne démarre pas

```bash
# Vérifier le ServiceAccount
kubectl get sa spark -n spark

# Créer si manquant
kubectl create sa spark -n spark

# Vérifier les permissions
kubectl get clusterrolebinding | grep spark
```

### Erreur S3

```bash
# Tester la connexion à MinIO
kubectl run -it --rm test --image=busybox -n spark -- sh
wget -O- http://minio.minio.svc:9000/minio/health/live
```

### OOM (Out of Memory)

Augmenter la mémoire :

```yaml
executor:
  memory: "8g"  # Au lieu de 4g
  memoryOverhead: "2g"
```

## 📊 Monitoring

### Spark UI

Le Spark UI est accessible via port-forward :

```bash
# Trouver le driver pod
POD=$(kubectl get pods -n spark -l spark-role=driver -o jsonpath='{.items[0].metadata.name}')

# Port-forward vers Spark UI
kubectl port-forward -n spark $POD 4040:4040

# Ouvrir http://localhost:4040
```

## 📝 CHANGELOG

### 2025-11-21
- ✅ Déploiement Spark Operator
- ✅ Namespace spark créé
- ✅ ServiceAccount configuré
- ✅ Exemples de jobs fournis

---

**Maintainer**: Data Platform Team  
**Last Updated**: 2025-11-21

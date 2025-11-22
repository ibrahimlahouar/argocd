# 🔍 Trino - Distributed SQL Query Engine

Trino (anciennement PrestoSQL) est un moteur de requêtes SQL distribué pour interroger des données à grande échelle.

## 📋 Informations

- **Namespace**: `trino`
- **Chart Source**: `trino/trino`
- **Version**: Latest (460+)
- **Image**: `trinodb/trino:latest`
- **Port**: 8080

## 🎯 Architecture

```
┌─────────────────────────────────────┐
│         Trino Coordinator           │
│  • Query planning                   │
│  • Query execution orchestration    │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│         Trino Workers (3x)          │
│  • Data processing                  │
│  • Query execution                  │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│         Data Sources                │
│  • MinIO (Iceberg tables)           │
│  • PostgreSQL                       │
│  • MySQL                            │
└─────────────────────────────────────┘
```

## 🚀 Installation

### Via Helm Chart Official

```bash
# Ajouter le repository Trino
helm repo add trino https://trinodb.github.io/charts
helm repo update

# Installer Trino
helm install trino trino/trino \
  --namespace trino \
  --create-namespace \
  --values values.yaml

# Vérifier le déploiement
kubectl get pods -n trino
```

### Installation Rapide (version par défaut)

```bash
kubectl create namespace trino
helm install trino trino/trino -n trino
```

## ⚙️ Configuration

### Coordinator Config

```properties
# config.properties
coordinator=true
node-scheduler.include-coordinator=false
http-server.http.port=8080
discovery.uri=http://localhost:8080
```

### Worker Config

```properties
# config.properties
coordinator=false
http-server.http.port=8080
discovery.uri=http://trino:8080
```

### JVM Config

```
# jvm.config
-server
-Xmx8G
-XX:+UseG1GC
-XX:G1HeapRegionSize=32M
-XX:+UseGCOverheadLimit
-XX:+ExplicitGCInvokesConcurrent
```

### Catalogs

#### MinIO / Iceberg

```properties
# catalog/iceberg.properties
connector.name=iceberg
iceberg.catalog.type=hadoop
hive.metastore.uri=thrift://hive-metastore:9083
iceberg.file-format=PARQUET
hive.s3.endpoint=http://minio.minio.svc:9000
hive.s3.path-style-access=true
hive.s3.aws-access-key=minioadmin
hive.s3.aws-secret-key=minioadmin123
```

#### PostgreSQL

```properties
# catalog/postgresql.properties
connector.name=postgresql
connection-url=jdbc:postgresql://postgres:5432/mydb
connection-user=admin
connection-password=password
```

## 🔧 Utilisation

### Via CLI

```bash
# Installer Trino CLI
curl -o trino https://repo1.maven.org/maven2/io/trino/trino-cli/469/trino-cli-469-executable.jar
chmod +x trino

# Se connecter
./trino --server http://10.10.0.101:8080 --user admin

# Ou depuis le cluster
kubectl exec -it -n trino trino-coordinator-0 -- trino
```

### Requêtes Exemple

```sql
-- Voir les catalogs
SHOW CATALOGS;

-- Voir les schemas
SHOW SCHEMAS FROM iceberg;

-- Créer une table
CREATE TABLE iceberg.mydb.users (
  id INTEGER,
  name VARCHAR,
  email VARCHAR,
  created_at TIMESTAMP
)
WITH (
  format = 'PARQUET',
  partitioning = ARRAY['day(created_at)']
);

-- Insérer des données
INSERT INTO iceberg.mydb.users VALUES
  (1, 'Alice', 'alice@example.com', CURRENT_TIMESTAMP),
  (2, 'Bob', 'bob@example.com', CURRENT_TIMESTAMP);

-- Query
SELECT * FROM iceberg.mydb.users;

-- Join entre sources différentes
SELECT 
  u.name,
  o.total_amount
FROM iceberg.mydb.users u
JOIN postgresql.public.orders o ON u.id = o.user_id;
```

## 🎯 Intégration Python

### Avec trino-python-client

```python
from trino.dbapi import connect

conn = connect(
    host='10.10.0.101',
    port=8080,
    user='admin',
    catalog='iceberg',
    schema='mydb'
)

cursor = conn.cursor()
cursor.execute('SELECT * FROM users')
rows = cursor.fetchall()

for row in rows:
    print(row)
```

### Avec SQLAlchemy

```python
from sqlalchemy import create_engine

engine = create_engine('trino://admin@10.10.0.101:8080/iceberg/mydb')

import pandas as pd
df = pd.read_sql('SELECT * FROM users', engine)
print(df)
```

## 📊 Web UI

Trino expose une UI web sur le port 8080 :

```bash
# Tunnel SSH
ssh -L 8081:10.10.0.101:8080 -i ~/.ssh/id_ed25519 root@135.181.211.227

# Ouvrir http://localhost:8081
```

Fonctionnalités UI :
- Vue des queries en cours
- Historique des queries
- Statistiques de performance
- Vue des workers

## 🐛 Troubleshooting

### Query échoue avec "No nodes available"

```bash
# Vérifier que les workers sont up
kubectl get pods -n trino

# Vérifier les logs coordinator
kubectl logs -n trino trino-coordinator-0

# Vérifier les logs workers
kubectl logs -n trino trino-worker-0
```

### Problème de connexion à MinIO

```bash
# Tester depuis un pod Trino
kubectl exec -it -n trino trino-coordinator-0 -- bash
curl http://minio.minio.svc:9000/minio/health/live
```

### OOM (Out of Memory)

Augmenter la mémoire JVM dans `jvm.config` :

```
-Xmx16G  # Au lieu de 8G
```

## 📊 Performance Tuning

### Pour gros volumes

```properties
# config.properties
query.max-memory=50GB
query.max-memory-per-node=10GB
query.max-total-memory-per-node=12GB

# Parallelisme
task.concurrency=16
task.max-worker-threads=64
```

## 📝 CHANGELOG

### 2025-11-21
- ✅ Migration vers Helm chart officiel (version latest)
- ✅ Intégration MinIO/Iceberg
- ✅ 1 Coordinator + 3 Workers
- ✅ Suppression de l'image custom

---

**Maintainer**: Data Platform Team  
**Last Updated**: 2025-11-21

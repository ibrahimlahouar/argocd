# 🔐 HashiCorp Vault - Secrets Management

Vault est un outil de gestion de secrets, de chiffrement et de contrôle d'accès.

## 📋 Informations

- **Namespace**: `vault`
- **Chart Source**: `hashicorp/vault`
- **Version**: 1.x
- **Mode**: Dev (standalone)

## 🎯 Configuration

### Accès

- **UI**: `http://10.10.0.101:30820`
- **Token Root**: `root`
- **API**: `http://10.10.0.101:30820`

## 🚀 Installation

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --values values.yaml
```

## ⚙️ Configuration values.yaml

```yaml
server:
  dev:
    enabled: true  # Mode dev pour POC
    devRootToken: "root"
  
  service:
    type: NodePort
    nodePort: 30820
  
  dataStorage:
    enabled: true
    size: 10Gi
  
  resources:
    requests:
      memory: 256Mi
      cpu: 250m
    limits:
      memory: 512Mi
      cpu: 500m

ui:
  enabled: true
```

## 🔧 Utilisation

### Via UI Web

1. Accéder à `http://10.10.0.101:30820`
2. Login avec token: `root`
3. Créer/lire des secrets

### Via CLI (kubectl exec)

```bash
# Accéder au pod Vault
kubectl exec -n vault vault-0 -- vault status

# Lister les secrets
kubectl exec -n vault vault-0 -- vault kv list secret/

# Créer un secret
kubectl exec -n vault vault-0 -- \
  vault kv put secret/myapp \
    api_key=xyz123 \
    db_password=secret456

# Lire un secret
kubectl exec -n vault vault-0 -- \
  vault kv get secret/myapp

# Format JSON
kubectl exec -n vault vault-0 -- \
  vault kv get -format=json secret/myapp
```

## 📦 Secrets Stockés

### MinIO Credentials

```bash
kubectl exec -n vault vault-0 -- \
  vault kv put secret/minio \
    access_key=minioadmin \
    secret_key=minioadmin123 \
    endpoint=http://minio.minio.svc:9000
```

### Database Credentials (exemple)

```bash
kubectl exec -n vault vault-0 -- \
  vault kv put secret/postgres \
    username=admin \
    password=strongpassword \
    host=postgres.database.svc \
    port=5432 \
    database=mydb
```

## 🔐 Intégration Kubernetes

### Vault Agent Injector

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "myapp"
    vault.hashicorp.com/agent-inject-secret-config: "secret/myapp"
spec:
  serviceAccountName: myapp
  containers:
  - name: app
    image: myapp:latest
    # Secrets injectés dans /vault/secrets/config
```

### External Secrets Operator (alternatif)

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: minio-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: minio-credentials
  data:
  - secretKey: access_key
    remoteRef:
      key: secret/minio
      property: access_key
```

## 🐛 Troubleshooting

### Vault sealed

```bash
# Vérifier le status
kubectl exec -n vault vault-0 -- vault status

# Si sealed, unsealer (mode prod uniquement)
kubectl exec -n vault vault-0 -- vault operator unseal <key1>
kubectl exec -n vault vault-0 -- vault operator unseal <key2>
kubectl exec -n vault vault-0 -- vault operator unseal <key3>
```

### Token expiré

En mode dev, le token `root` ne expire jamais. En prod :

```bash
# Créer un nouveau token
kubectl exec -n vault vault-0 -- \
  vault token create -policy=default
```

## 📊 Mode Production

### Configuration HA

```yaml
server:
  dev:
    enabled: false
  
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
  
  dataStorage:
    enabled: true
    size: 50Gi
    storageClass: longhorn
```

### Initialisation

```bash
# Initialiser Vault
kubectl exec -n vault vault-0 -- vault operator init

# Sauvegarder les unseal keys ET le root token !
```

## 📝 CHANGELOG

### 2025-11-21
- ✅ Déploiement en mode dev
- ✅ Token root: `root`
- ✅ Secrets MinIO configurés

---

**Maintainer**: Data Platform Team  
**Last Updated**: 2025-11-21

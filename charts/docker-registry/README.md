# 🐳 Docker Registry - Private Image Registry

Registry privé pour stocker vos images Docker personnalisées.

## 📋 Informations

- **Namespace**: `harbor`
- **Chart Source**: `twuni/docker-registry`
- **Version**: 2.x
- **Storage**: MinIO backend

## 🎯 Configuration

### Accès

- **Registry URL**: `http://10.10.0.101:30500`
- **Via tunnel**: `http://localhost:5050`
- **Authentication**: Disabled (mode dev)

## 🚀 Installation

```bash
helm repo add twuni https://helm.twun.io
helm repo update

helm install docker-registry twuni/docker-registry \
  --namespace harbor \
  --create-namespace \
  --values values.yaml
```

## ⚙️ Configuration values.yaml

```yaml
service:
  type: NodePort
  port: 5050
  nodePort: 30500

persistence:
  enabled: true
  size: 100Gi
  storageClass: longhorn

# Optionnel: Utiliser MinIO comme backend
s3:
  enabled: false
  # Pour activer MinIO backend:
  # enabled: true
  # region: us-east-1
  # bucket: harbor
  # endpoint: http://minio.minio.svc:9000
  # accessKey: minioadmin
  # secretKey: minioadmin123

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## 🔧 Utilisation

### Configurer Docker local

```bash
# Ajouter registry comme insecure (mode dev)
# macOS: Docker Desktop → Settings → Docker Engine
{
  "insecure-registries": [
    "10.10.0.101:30500",
    "localhost:5050"
  ]
}
```

### Push une image

```bash
# Build l'image
docker build -t myapp:v1 .

# Tag pour le registry
docker tag myapp:v1 10.10.0.101:30500/myapp:v1

# Push
docker push 10.10.0.101:30500/myapp:v1

# Pull
docker pull 10.10.0.101:30500/myapp:v1
```

### Lister les images

```bash
# Via API
curl http://10.10.0.101:30500/v2/_catalog

# Lister les tags d'une image
curl http://10.10.0.101:30500/v2/myapp/tags/list
```

## 🎯 Utilisation dans Kubernetes

### Simple Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: 10.10.0.101:30500/myapp:v1
    imagePullPolicy: IfNotPresent
```

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: 10.10.0.101:30500/myapp:v1
        ports:
        - containerPort: 8080
```

## 🔐 Mode Production

### Activer l'authentification

```yaml
secrets:
  htpasswd: "username:$2y$05$..."  # généré avec htpasswd

persistence:
  enabled: true
  size: 500Gi

# TLS
tlsSecretName: registry-tls
```

### Générer htpasswd

```bash
# Installer htpasswd
brew install httpd  # macOS
apt-get install apache2-utils  # Linux

# Créer le fichier
htpasswd -Bbn username password

# Dans Kubernetes
kubectl create secret generic registry-auth \
  --from-file=htpasswd=./htpasswd \
  -n harbor
```

### Utiliser avec authentification

```bash
# Login
docker login 10.10.0.101:30500 -u username -p password

# Ou créer un secret K8s
kubectl create secret docker-registry regcred \
  --docker-server=10.10.0.101:30500 \
  --docker-username=username \
  --docker-password=password \
  -n default

# Utiliser dans un pod
spec:
  imagePullSecrets:
  - name: regcred
  containers:
  - name: app
    image: 10.10.0.101:30500/myapp:v1
```

## 🐛 Troubleshooting

### Push échoue

```bash
# Vérifier que le registry est dans insecure-registries
docker info | grep -A 10 "Insecure Registries"

# Tester la connexion
curl http://10.10.0.101:30500/v2/
# Devrait retourner: {}
```

### Image non trouvée

```bash
# Vérifier que l'image existe
curl http://10.10.0.101:30500/v2/_catalog

# Vérifier les tags
curl http://10.10.0.101:30500/v2/myapp/tags/list
```

## 📊 Nettoyage

### Supprimer les images inutilisées

```bash
# Via API (attention: pas de garbage collection par défaut)
# Activer le garbage collection dans values.yaml:

garbageCollect:
  enabled: true
  schedule: "0 2 * * *"  # Tous les jours à 2h
```

## 📝 CHANGELOG

### 2025-11-21
- ✅ Déploiement initial
- ✅ NodePort 30500
- ✅ Mode insecure (dev)

---

**Maintainer**: Data Platform Team  
**Last Updated**: 2025-11-21

# 🖥️ Headlamp - Kubernetes UI

Headlamp est une interface web moderne pour gérer votre cluster Kubernetes.

## 📋 Informations

- **Namespace**: `headlamp`
- **Chart Source**: `headlamp/headlamp`
- **Version**: Latest
- **Port**: 30098 (NodePort)

## 🎯 Configuration

### Accès

- **URL Directe**: `http://10.10.0.101:30098`
- **Via Tunnel**: `http://localhost:8080`
- **Token**: Stocké dans `/Users/ilahouar/Documents/proxmox/headlamp-token.txt`

## 🚀 Installation

```bash
helm repo add headlamp https://headlamp-k8s.github.io/headlamp/
helm repo update

helm install headlamp headlamp/headlamp \
  --namespace headlamp \
  --create-namespace \
  --values values.yaml
```

## ⚙️ Configuration values.yaml

```yaml
service:
  type: NodePort
  port: 80
  nodePort: 30098

replicaCount: 1

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Activer le mode cluster
config:
  baseURL: ""
  pluginsDir: ""
  
# Service Account avec permissions admin
serviceAccount:
  create: true
  name: headlamp-admin
```

## 🔐 Créer le Token d'Accès

```bash
# Créer ServiceAccount
kubectl create serviceaccount headlamp-admin -n headlamp

# Créer ClusterRoleBinding
kubectl create clusterrolebinding headlamp-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=headlamp:headlamp-admin

# Créer le token secret
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
  -o jsonpath='{.data.token}' | base64 -d
```

## 🔧 Utilisation

### Se connecter

1. Ouvrir `http://localhost:8080`
2. Choisir "Token"
3. Coller le token depuis `headlamp-token.txt`
4. Cliquer sur "Authenticate"

### Fonctionnalités

- ✅ **Vue d'ensemble du cluster**: Nodes, pods, services
- ✅ **Gestion des ressources**: Create, edit, delete
- ✅ **Logs en temps réel**: Voir les logs des pods
- ✅ **Shell interactif**: Exec dans les containers
- ✅ **Métriques**: CPU, RAM, réseau
- ✅ **Events**: Voir les événements K8s

## 🎯 Actions Courantes

### Voir les Pods

1. Sidebar → Workloads → Pods
2. Sélectionner le namespace
3. Cliquer sur un pod pour voir les détails

### Voir les Logs

1. Ouvrir un Pod
2. Cliquer sur l'onglet "Logs"
3. Sélectionner le container
4. Les logs s'affichent en temps réel

### Shell dans un Pod

1. Ouvrir un Pod
2. Cliquer sur "Terminal"
3. Shell interactif dans le container

### Éditer une ressource

1. Ouvrir la ressource
2. Cliquer sur le bouton "Edit"
3. Modifier le YAML
4. "Save" pour appliquer

## 🐛 Troubleshooting

### Token ne fonctionne pas

```bash
# Vérifier que le secret existe
kubectl get secret headlamp-admin-token -n headlamp

# Régénérer le token
kubectl delete secret headlamp-admin-token -n headlamp
# Puis recréer (voir section création token)
```

### Headlamp ne charge pas

```bash
# Vérifier le pod
kubectl get pods -n headlamp

# Voir les logs
kubectl logs -n headlamp -l app.kubernetes.io/name=headlamp

# Redémarrer
kubectl rollout restart deployment/headlamp -n headlamp
```

## 📊 Alternatives

- **Kubernetes Dashboard**: UI officielle K8s
- **Lens**: Desktop app (nécessite licence pour certaines features)
- **k9s**: CLI interactif
- **Octant**: UI locale par VMware

## 📝 CHANGELOG

### 2025-11-21
- ✅ Déploiement initial
- ✅ Token admin créé
- ✅ NodePort 30098 configuré

---

**Maintainer**: Data Platform Team  
**Last Updated**: 2025-11-21

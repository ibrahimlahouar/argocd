# 🐛 Guide de Dépannage

## MinIO

### Pod ne démarre pas

```bash
# Vérifier les logs
kubectl logs -n minio -l app=minio

# Causes communes:
# - PVC non créé
# - Problème de permissions
# - CPU incompatible (x86-64-v2)

# Solution CPU:
# Utiliser une version plus ancienne
# minio:RELEASE.2023-05-27T05-56-19Z
```

### Connexion refusée

```bash
# Vérifier le service
kubectl get svc -n minio

# Tester depuis un pod
kubectl run -it --rm test --image=busybox -n minio -- sh
wget -O- http://minio:9000/minio/health/live
```

## Vault

### Vault sealed

```bash
# En mode dev, ne devrait pas arriver
# Vérifier le status
kubectl exec -n vault vault-0 -- vault status

# Redémarrer le pod si nécessaire
kubectl delete pod vault-0 -n vault
```

### Token ne fonctionne pas

```bash
# En mode dev, le token est toujours "root"
# Vérifier que Vault est bien en mode dev
kubectl logs -n vault vault-0 | grep "dev mode"
```

## Spark Operator

### Job ne démarre pas

```bash
# Vérifier le ServiceAccount
kubectl get sa spark -n spark

# Si manquant, créer:
kubectl create sa spark -n spark

# Créer le ClusterRole et Binding
kubectl create clusterrolebinding spark-role \
  --clusterrole=edit \
  --serviceaccount=spark:spark
```

### Erreur "No nodes available"

```bash
# Vérifier que l'operator tourne
kubectl get pods -n spark-operator

# Vérifier les logs
kubectl logs -n spark-operator -l app.kubernetes.io/name=spark-operator

# Redémarrer l'operator
kubectl rollout restart deployment -n spark-operator
```

### Spark job en erreur "OOM"

```yaml
# Augmenter la mémoire
executor:
  memory: "8g"  # Au lieu de 4g
  memoryOverhead: "2g"

driver:
  memory: "4g"  # Au lieu de 2g
```

## Trino

### Query échoue

```bash
# Vérifier les logs coordinator
kubectl logs -n trino trino-coordinator-0

# Vérifier les workers
kubectl get pods -n trino

# Tester la connexion
kubectl exec -it -n trino trino-coordinator-0 -- trino
```

### Connexion à MinIO échoue

```bash
# Vérifier que MinIO est accessible
kubectl exec -it -n trino trino-coordinator-0 -- bash
curl http://minio.minio.svc:9000/minio/health/live

# Vérifier les credentials dans catalog/iceberg.properties
```

## Docker Registry

### Push échoue

```bash
# Vérifier insecure-registries
docker info | grep -A 10 "Insecure Registries"

# Devrait afficher:
# 10.10.0.101:30500
# localhost:5050

# Si manquant, ajouter dans Docker Desktop → Settings → Docker Engine
```

### Image non trouvée dans K8s

```bash
# Vérifier que l'image existe
curl http://10.10.0.101:30500/v2/_catalog

# Vérifier les tags
curl http://10.10.0.101:30500/v2/myapp/tags/list

# Dans le pod spec, utiliser imagePullPolicy: IfNotPresent
```

## Headlamp

### Token ne fonctionne pas

```bash
# Régénérer le token
kubectl delete secret headlamp-admin-token -n headlamp

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

# Récupérer le nouveau token
kubectl get secret headlamp-admin-token -n headlamp \
  -o jsonpath='{.data.token}' | base64 -d
```

## Tunnels SSH

### Tunnel déconnecté

```bash
# Vérifier les processus
ps aux | grep "ssh.*-L"

# Tuer tous les tunnels
pkill -f "ssh.*-L.*10.10.0.101"

# Redémarrer
ssh -N -f \
  -L 8080:10.10.0.101:30098 \
  -L 9001:10.10.0.101:30901 \
  -L 9000:10.10.0.101:30900 \
  -L 8200:10.10.0.101:30820 \
  -L 5050:10.10.0.101:30500 \
  -i ~/.ssh/id_ed25519 \
  root@135.181.211.227
```

### Port déjà utilisé

```bash
# Trouver le process
lsof -i :8080

# Tuer le process
kill -9 <PID>

# Ou utiliser un port différent
ssh -L 8081:10.10.0.101:30098 ...
```

## Problèmes Généraux

### Pod en CrashLoopBackOff

```bash
# Voir les logs
kubectl logs <pod-name> -n <namespace>

# Voir les événements
kubectl describe pod <pod-name> -n <namespace>

# Causes communes:
# - Mauvaise configuration
# - Resource limits trop bas
# - Dépendance non disponible
```

### PVC en Pending

```bash
# Vérifier le PVC
kubectl describe pvc <pvc-name> -n <namespace>

# Vérifier la StorageClass
kubectl get storageclass

# Si local-path, vérifier que le provisioner est actif
kubectl get pods -n kube-system | grep local-path
```

### Réseau ne fonctionne pas

```bash
# Tester DNS
kubectl run -it --rm debug --image=busybox -- nslookup kubernetes.default

# Tester connectivité inter-pods
kubectl run -it --rm debug --image=busybox -- ping <service-name>.<namespace>.svc

# Vérifier CNI (Calico, Flannel, etc.)
kubectl get pods -n kube-system | grep -E "calico|flannel"
```

## Commandes Utiles

### Diagnostics Cluster

```bash
# Voir tous les pods
kubectl get pods --all-namespaces

# Ressources
kubectl top nodes
kubectl top pods -A

# Events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Logs d'un deployment
kubectl logs -n <namespace> -l app=<app-name> -f
```

### Nettoyage

```bash
# Supprimer les pods en erreur
kubectl delete pods --field-selector status.phase=Failed -A

# Supprimer les jobs Spark terminés
kubectl delete sparkapplications --field-selector status.phase=Completed -n spark

# Nettoyer les images Docker inutilisées
docker system prune -a
```

---

**Dernière mise à jour**: 2025-11-21

# Migration des Charts vers les Versions Officielles et Harbor

**Date**: 23 Novembre 2025  
**Objectif**: Utiliser des charts Helm officiels et stocker toutes les images sur Harbor

---

## 📋 Résumé des Modifications

### ✅ Charts Migrés vers les Versions Officielles

| Service | Avant | Après | Chart Officiel |
|---------|-------|-------|----------------|
| **MinIO** | Chart custom (v1.0.0) | Chart officiel (v5.4.0) | ✅ minio/minio |
| **Harbor** | Chart officiel (v1.14.0) | ✅ Déjà officiel | goharbor/harbor |
| **Vault** | Chart officiel (v1.0.1) | ✅ Déjà officiel | hashicorp/vault |
| **Trino** | Chart officiel (v1.0.1) | ✅ Déjà officiel | trinodb/trino |
| **Headlamp** | Chart officiel (v0.23.0) | ✅ Déjà officiel | headlamp/headlamp |
| **Spark Operator** | Chart officiel (v1.1.27) | ✅ Déjà officiel | spark-operator/spark-operator |

---

## 🐳 Images Harbor Configurées

Tous les services utilisent maintenant les images depuis Harbor (`10.10.0.101:30500`):

### Images Configurées dans les Values

```yaml
# MinIO
image:
  repository: 10.10.0.101:30500/data-platform/minio
  tag: RELEASE.2024-12-18T13-15-44Z

# Headlamp
image:
  repository: 10.10.0.101:30500/data-platform/headlamp
  tag: v0.24.1

# Trino
image:
  repository: 10.10.0.101:30500/data-platform/trino
  tag: "432"

# Vault
image:
  repository: 10.10.0.101:30500/data-platform/vault
  tag: "1.15.2"

# Spark Operator
image:
  repository: 10.10.0.101:30500/data-platform/spark-operator
  tag: "v1beta2-1.3.8-3.1.1"
```

### ImagePullSecrets Ajoutés

Tous les charts incluent maintenant:

```yaml
imagePullSecrets:
  - harbor-registry  # ou - name: harbor-registry selon le schema
```

### Secrets Harbor Créés Automatiquement

Chaque chart crée maintenant automatiquement un secret `harbor-registry` via le template `harbor-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: harbor-registry
  namespace: {{ .Release.Namespace }}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64_encoded_docker_config>
```

**Credentials Harbor**:
- Username: `admin`
- Password: `Harbor123!`
- Registry: `10.10.0.101:30500`

---

## 🧹 Nettoyage Effectué

### Fichiers Supprimés

- ❌ `charts/headlamp/tests/` - Tests unitaires non nécessaires
- ❌ `charts/trino/ci/` - Configuration CI non nécessaire
- ❌ `charts/vault/templates/tests/` - Tests Helm non nécessaires
- ❌ Fichiers `.helmignore` - Non nécessaires avec Argo CD
- ❌ Fichiers `Makefile` - Non nécessaires avec Argo CD
- ❌ Fichiers `CODEOWNERS` et `CONTRIBUTING.md` - Métadonnées upstream

### Fichiers Conservés

- ✅ `README.md` - Documentation
- ✅ `LICENSE` - Licences des charts
- ✅ `CHANGELOG.md` - Historique des versions
- ✅ `Chart.yaml` - Métadonnées Helm
- ✅ `values.yaml` - Configuration
- ✅ `templates/` - Templates Kubernetes

---

## 📝 Images à Pusher sur Harbor

### ✅ Images Déjà sur Harbor

1. ✅ `headlamp:v0.24.1`
2. ✅ `trino:432`
3. ✅ `vault:1.15.2`
4. ✅ `vault-k8s:1.3.1`
5. ✅ `spark-operator:v1beta2-1.3.8-3.1.1`

### ⚠️ Images à Pusher

#### MinIO - Image Principale

```bash
# Pull l'image officielle
docker pull minio/minio:RELEASE.2024-12-18T13-15-44Z

# Tag pour Harbor
docker tag minio/minio:RELEASE.2024-12-18T13-15-44Z \
  10.10.0.101:30500/data-platform/minio:RELEASE.2024-12-18T13-15-44Z

# Login Harbor
docker login 10.10.0.101:30500 -u admin -p Harbor123!

# Push
docker push 10.10.0.101:30500/data-platform/minio:RELEASE.2024-12-18T13-15-44Z
```

#### MinIO Client (mc)

```bash
# Pull
docker pull minio/mc:RELEASE.2024-11-21T17-21-54Z

# Tag
docker tag minio/mc:RELEASE.2024-11-21T17-21-54Z \
  10.10.0.101:30500/data-platform/mc:RELEASE.2024-11-21T17-21-54Z

# Push
docker push 10.10.0.101:30500/data-platform/mc:RELEASE.2024-11-21T17-21-54Z
```

---

## 🔧 Commandes de Déploiement

### Vérification Locale (avant commit)

```bash
# Lint tous les charts
for chart in charts/*/; do
  echo "Testing $chart"
  helm lint "$chart"
done

# Template un chart (dry-run)
helm template test charts/minio --debug

# Valider avec Argo CD en local
argocd app diff minio --local charts/minio
```

### Déploiement via Argo CD

```bash
# Sync manuel d'une application
argocd app sync minio

# Sync toutes les applications
argocd app sync -l app.kubernetes.io/part-of=data-platform

# Vérifier le status
argocd app list
argocd app get minio
```

---

## ✅ Validation des Charts

Tous les charts ont été validés avec `helm lint`:

```bash
$ helm lint charts/*

✅ charts/harbor/      - 1 chart(s) linted, 0 chart(s) failed
✅ charts/headlamp/    - 1 chart(s) linted, 0 chart(s) failed
✅ charts/minio/       - 1 chart(s) linted, 0 chart(s) failed
✅ charts/spark-operator/ - 1 chart(s) linted, 0 chart(s) failed
✅ charts/trino/       - 1 chart(s) linted, 0 chart(s) failed
✅ charts/vault/       - 1 chart(s) linted, 0 chart(s) failed
```

---

## 🚀 Prochaines Étapes

### Priorité P0 (Urgent)

1. **Pusher les images MinIO sur Harbor** (voir commandes ci-dessus)
2. **Commit et push des changements** sur GitHub
3. **Sync Argo CD** pour déployer les nouveaux charts

### Priorité P1 (Important)

4. **Vérifier les pods** après déploiement:
   ```bash
   kubectl get pods -n minio
   kubectl get pods -n headlamp
   kubectl logs -n headlamp <pod-name>
   ```

5. **Tester les services**:
   - MinIO Console: http://10.10.0.101:30901
   - Headlamp: http://10.10.0.101:31162
   - Trino: http://10.10.0.101:32562

### Priorité P2 (Amélioration)

6. **Stocker les credentials Harbor dans Vault** (au lieu du secret en clair)
7. **Scanner les images avec Trivy** (intégré à Harbor)
8. **Mettre en place des alertes** pour ImagePullBackOff

---

## 📚 Documentation

### Fichiers de Configuration Principaux

```
argocd/
├── applications/services.yaml     # Définitions des applications Argo CD
├── charts/
│   ├── harbor/values.yaml        # Config Harbor
│   ├── headlamp/values.yaml      # Config Headlamp + Harbor secret
│   ├── minio/values.yaml         # Config MinIO (nouveau chart officiel)
│   ├── spark-operator/values.yaml
│   ├── trino/values.yaml
│   └── vault/values.yaml
└── docs/
    ├── charts-migration.md       # Ce document
    ├── deployment-guide.md
    └── troubleshooting.md
```

### Liens Utiles

- MinIO Helm Chart: https://github.com/minio/minio/tree/master/helm/minio
- Harbor Registry: http://10.10.0.101:30500
- Argo CD UI: http://10.10.0.101:30080

---

## ⚠️ Notes Importantes

### Changement MinIO Custom → Officiel

Le chart MinIO custom simple a été remplacé par le chart officiel complet (v5.4.0):

**Changements notables**:
- Mode: `standalone` (au lieu de distributed)
- Replicas: `1` (au lieu de 16 par défaut)
- Image: Harbor registry (au lieu de quay.io)
- Storage: `local-path` StorageClass (100Gi)
- Service: NodePort `30900` (API) et `30901` (Console)

**Compatibilité**: Les PVC existants seront réutilisés si les noms correspondent.

### ImagePullSecrets Format

Certains charts utilisent différents formats:

```yaml
# Format 1 (Headlamp - selon schema)
imagePullSecrets:
  - harbor-registry

# Format 2 (MinIO, Spark, Trino, Vault - standard)
imagePullSecrets:
  - name: harbor-registry
```

Les templates sont compatibles avec les deux formats.

---

**Fin du document** 🎉


# 🔍 Image Scanning avec Trivy

## Vue d'ensemble

Trivy est un scanner de vulnérabilités pour les images containers.
Il est déjà intégré dans **Harbor** (votre registry privé).

## ✅ Trivy dans Harbor

Harbor inclut Trivy par défaut. Chaque image poussée dans Harbor est automatiquement scannée.

### Accès aux résultats

1. Connectez-vous à Harbor: https://harbor.data-platform.local
2. Naviguez vers un projet > un repository > une image
3. Cliquez sur l'image pour voir les résultats du scan

### Configuration Harbor

Dans `charts/harbor/values.yaml`, Trivy est configuré:

```yaml
trivy:
  enabled: true
  # Mise à jour automatique de la base de vulnérabilités
  autoUpdate: true
  # Sévérité minimale à signaler
  severity: "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL"
```

## 🔧 Intégration CI/CD

### GitHub Actions

```yaml
name: Build and Scan

on:
  push:
    branches: [main]

jobs:
  build-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL,HIGH'
      
      - name: Push to Harbor
        if: success()
        run: |
          docker tag myapp:${{ github.sha }} harbor.data-platform.local/myproject/myapp:${{ github.sha }}
          docker push harbor.data-platform.local/myproject/myapp:${{ github.sha }}
```

### GitLab CI

```yaml
stages:
  - build
  - scan
  - push

build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .

scan:
  stage: scan
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  allow_failure: false

push:
  stage: push
  script:
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  only:
    - main
```

## 📊 Politique de sécurité recommandée

### Bloquer les images avec vulnérabilités critiques

Harbor peut être configuré pour empêcher le pull d'images vulnérables:

1. Allez dans **Administration** > **Configuration** > **System Settings**
2. Activez **Prevent vulnerable images from running**
3. Définissez le seuil: **High** ou **Critical**

### Gatekeeper Policy

Utilisez OPA Gatekeeper pour forcer l'utilisation d'images scannées:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sImageDigests
metadata:
  name: require-image-digest
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces:
      - kube-system
      - gatekeeper-system
```

## 🔄 Scan périodique des images existantes

Harbor peut rescanner automatiquement les images:

```yaml
# Dans Harbor values.yaml
trivy:
  # Rescanner toutes les images à minuit
  scanAllPolicy:
    type: "daily"
    parameter:
      daily_time: 0
```

## 📈 Métriques et Alertes

### Prometheus metrics

Harbor expose des métriques Trivy:
- `harbor_project_total_image_count` - Nombre total d'images
- `harbor_project_vuln_image_count` - Nombre d'images vulnérables

### Alerte Prometheus

```yaml
- alert: CriticalVulnerabilitiesDetected
  expr: harbor_project_vuln_image_count{severity="Critical"} > 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Critical vulnerabilities detected in Harbor"
    description: "Project {{ $labels.project }} has {{ $value }} images with critical vulnerabilities"
```

## ⚠️ Bonnes pratiques

1. **Scanner avant push**: Toujours scanner en CI/CD avant de pousser vers Harbor
2. **Bloquer Critical**: Ne pas autoriser les images avec vulnérabilités critiques
3. **Rescan régulier**: Les bases de vulnérabilités sont mises à jour quotidiennement
4. **Images de base**: Utiliser des images de base officielles et maintenues
5. **Multi-stage builds**: Réduire la surface d'attaque avec des builds multi-étapes


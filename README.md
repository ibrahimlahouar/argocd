# 🚀# Data Platform (GitOps Managed)

This repository contains the Helm charts, documentation, and ArgoCD configurations for the Data Platform.
All deployments are managed automatically via ArgoCD.

## 📋 Vue d'overview

Cette plateforme de données est déployée sur un cluster Kubernetes de **10 VMs** (3 masters + 7 workers) avec **1 To de stockage** et **128 GB RAM**.

## 🎯 Services Déployés

| Service | Namespace | Chart Helm | Version | Status |
|---------|-----------|------------|---------|--------|
| MinIO | `minio` | [minio](./charts/minio/) | Latest | ✅ Déployé |
| Docker Registry | `harbor` | [docker-registry](./charts/docker-registry/) | 2.x | ✅ Déployé |
| HashiCorp Vault | `vault` | [vault](./charts/vault/) | 1.x | ✅ Déployé |
| Spark Operator | `spark-operator` | [spark-operator](./charts/spark-operator/) | 1.x | ✅ Déployé |
| Headlamp | `headlamp` | [headlamp](./charts/headlamp/) | Latest | ✅ Déployé |
| Trino | `trino` | [trino](./charts/trino/) | Latest | ✅ Déployé |
| Airflow | `airflow` | [airflow](./charts/airflow/) | - | 📋 Planifié |
| Superset | `superset` | [superset](./charts/superset/) | - | 📋 Planifié |
| Jupyter | `jupyter` | [jupyterhub](./charts/jupyter/) | - | 📋 Planifié |

## 📁 Structure du Repository

```
data-platform/
├── README.md                          # Ce fichier
├── charts/                            # Charts Helm par service
│   ├── minio/
│   │   ├── README.md                  # Documentation MinIO
│   │   ├── values.yaml                # Valeurs de production
│   │   ├── values-dev.yaml            # Valeurs de développement
│   │   └── CHANGELOG.md               # Historique des changements
│   ├── vault/
│   ├── spark-operator/
│   ├── docker-registry/
│   ├── headlamp/
│   └── trino/
├── docs/                              # Documentation générale
│   ├── architecture.md                # Architecture de la plateforme
│   ├── deployment-guide.md            # Guide de déploiement
│   ├── access-guide.md                # Guide d'accès aux services
│   └── troubleshooting.md             # Guide de dépannage
├── scripts/                           # Scripts utilitaires
│   ├── deploy-all.sh                  # Déployer tous les services
│   ├── update-chart.sh                # Mettre à jour un chart
│   └── backup.sh                      # Backup des configurations
└── environments/                      # Configurations par environnement
    ├── dev/
    └── prod/
```

## 🚀 Quick Start

### Prérequis

- Kubernetes cluster (v1.24+)
- ArgoCD installé (`argocd` namespace)
- `kubectl` configuré

### Déployer toute la plateforme (GitOps avec ArgoCD)

```bash
# Appliquer l'application racine ArgoCD
kubectl apply -n argocd -f root-app.yaml

# ArgoCD va créer et synchroniser automatiquement :
# - MinIO (chart officiel minio/minio)
# - Registry (déploiement simple docker-registry)
# - Vault, Trino, Headlamp, Spark Operator
```

### Gérer un service (exemple MinIO)

```bash
# Voir l'état de l'application MinIO
kubectl get application minio -n argocd

# Forcer une resynchronisation
kubectl patch application minio -n argocd \
  --type merge \
  -p '{"operation": {"sync": {"prune": true}}}'
```

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    INFRASTRUCTURE K8S                        │
│  • 10 VMs (3 masters + 7 workers)                           │
│  • 1 To stockage total                                       │
│  • 128 GB RAM total                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    DATA PLATFORM STACK                       │
│                                                              │
│  ✅ MinIO (S3 Storage)           → Port 30900/30901         │
│  ✅ Docker Registry               → Port 30500              │
│  ✅ HashiCorp Vault              → Port 30820               │
│  ✅ Spark Operator               → Jobs Spark K8s           │
│  ✅ Headlamp (K8s UI)            → Port 30098               │
│  ✅ Trino (SQL Engine)           → Helm Official            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Accès aux Services

Tous les services sont accessibles via tunnels SSH depuis votre poste local.

### Démarrer les tunnels

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

### URLs des services

- **Headlamp UI**: http://localhost:8080
- **MinIO Console**: http://localhost:9001 (`minioadmin` / `minioadmin123`)
- **MinIO API**: http://localhost:9000
- **Vault UI**: http://localhost:8200 (token: `root`)
- **Docker Registry**: http://localhost:5050

## 📚 Documentation

- [Architecture détaillée](./docs/architecture.md)
- [Guide de déploiement](./docs/deployment-guide.md)
- [Guide d'accès aux services](./docs/access-guide.md)
- [Troubleshooting](./docs/troubleshooting.md)

## 🛠️ Contribution

### Ajouter un nouveau service

1. Créer le dossier dans `charts/`
2. Ajouter le chart Helm
3. Créer la documentation `README.md`
4. Tester le déploiement
5. Mettre à jour ce README

### Format de documentation

Chaque chart doit contenir :
- `README.md` - Description, prérequis, installation
- `values.yaml` - Configuration de production
- `values-dev.yaml` - Configuration de développement
- `CHANGELOG.md` - Historique des versions

## 📝 License

MIT

## 👥 Maintainers

- Votre équipe Data Platform

---

**📌 Dernière mise à jour**: 2025-11-21

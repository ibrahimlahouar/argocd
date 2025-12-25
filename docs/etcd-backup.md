# 📦 Backup etcd - Guide complet

## Vue d'ensemble

etcd est la base de données clé-valeur qui stocke l'état de votre cluster Kubernetes.
Un backup régulier est **critique** pour la récupération en cas de désastre.

## 🔧 Méthode 1: Backup manuel depuis un master node

### Prérequis
- Accès SSH à un master node
- Certificats etcd disponibles (généralement dans `/etc/ssl/etcd/ssl/`)

### Commandes

```bash
# Se connecter à un master node
ssh user@master-node

# Variables (adapter selon votre configuration Kubespray)
ETCD_CERT_DIR="/etc/ssl/etcd/ssl"
ETCD_CA="${ETCD_CERT_DIR}/ca.pem"
ETCD_CERT="${ETCD_CERT_DIR}/admin-$(hostname).pem"
ETCD_KEY="${ETCD_CERT_DIR}/admin-$(hostname)-key.pem"
ETCD_ENDPOINTS="https://127.0.0.1:2379"
BACKUP_DIR="/var/backups/etcd"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Créer le répertoire de backup
sudo mkdir -p $BACKUP_DIR

# Créer le snapshot
sudo ETCDCTL_API=3 etcdctl snapshot save ${BACKUP_DIR}/etcd-snapshot-${TIMESTAMP}.db \
  --endpoints=${ETCD_ENDPOINTS} \
  --cacert=${ETCD_CA} \
  --cert=${ETCD_CERT} \
  --key=${ETCD_KEY}

# Vérifier le snapshot
sudo ETCDCTL_API=3 etcdctl snapshot status ${BACKUP_DIR}/etcd-snapshot-${TIMESTAMP}.db \
  --write-out=table
```

## 🔄 Méthode 2: Backup automatique avec Kubespray

Kubespray inclut un playbook pour les backups etcd.

### Commandes depuis le contrôleur Kubespray

```bash
cd kubespray

# Backup etcd
ansible-playbook -i inventory/mycluster/hosts.yaml \
  --become --become-user=root \
  playbooks/etcd_backup.yml

# Les backups sont créés dans /var/backups/kube_etcd/ sur les master nodes
```

## 📅 Automatisation avec Cron

Créer un script de backup automatique sur chaque master node :

### `/usr/local/bin/etcd-backup.sh`

```bash
#!/bin/bash
set -e

# Configuration
ETCD_CERT_DIR="/etc/ssl/etcd/ssl"
ETCD_CA="${ETCD_CERT_DIR}/ca.pem"
ETCD_CERT="${ETCD_CERT_DIR}/admin-$(hostname).pem"
ETCD_KEY="${ETCD_CERT_DIR}/admin-$(hostname)-key.pem"
ETCD_ENDPOINTS="https://127.0.0.1:2379"
BACKUP_DIR="/var/backups/etcd"
RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Créer le backup
mkdir -p $BACKUP_DIR
ETCDCTL_API=3 etcdctl snapshot save ${BACKUP_DIR}/etcd-snapshot-${TIMESTAMP}.db \
  --endpoints=${ETCD_ENDPOINTS} \
  --cacert=${ETCD_CA} \
  --cert=${ETCD_CERT} \
  --key=${ETCD_KEY}

# Compression
gzip ${BACKUP_DIR}/etcd-snapshot-${TIMESTAMP}.db

# Cleanup old backups
find $BACKUP_DIR -name "etcd-snapshot-*.db.gz" -mtime +${RETENTION_DAYS} -delete

# Log
echo "$(date): etcd backup created: etcd-snapshot-${TIMESTAMP}.db.gz" >> /var/log/etcd-backup.log
```

### Crontab (sur chaque master node)

```bash
# Backup etcd tous les jours à 1h du matin
0 1 * * * /usr/local/bin/etcd-backup.sh
```

## 🔄 Restauration

### En cas de désastre

```bash
# Arrêter etcd sur tous les masters
sudo systemctl stop etcd

# Restaurer le snapshot (sur chaque master)
sudo ETCDCTL_API=3 etcdctl snapshot restore /path/to/snapshot.db \
  --name=<node-name> \
  --initial-cluster=<initial-cluster> \
  --initial-cluster-token=<token> \
  --initial-advertise-peer-urls=https://<node-ip>:2380 \
  --data-dir=/var/lib/etcd-from-backup

# Mettre à jour la configuration etcd pour utiliser le nouveau data-dir
# Puis redémarrer etcd
sudo systemctl start etcd
```

## 📊 Monitoring

### Vérifier l'état d'etcd

```bash
# Health check
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=${ETCD_ENDPOINTS} \
  --cacert=${ETCD_CA} \
  --cert=${ETCD_CERT} \
  --key=${ETCD_KEY}

# Liste des membres
ETCDCTL_API=3 etcdctl member list \
  --endpoints=${ETCD_ENDPOINTS} \
  --cacert=${ETCD_CA} \
  --cert=${ETCD_CERT} \
  --key=${ETCD_KEY} \
  --write-out=table
```

## ⚠️ Recommandations

1. **Fréquence**: Backup au minimum 1x par jour
2. **Rétention**: Garder au moins 30 jours de backups
3. **Stockage externe**: Copier les backups vers un stockage externe (MinIO, S3, NFS)
4. **Test de restauration**: Tester la restauration régulièrement
5. **Alerting**: Configurer des alertes si le backup échoue

## 🔗 Intégration avec Velero

Velero peut être configuré pour inclure les backups etcd dans ses snapshots cluster.
Cependant, il est recommandé de maintenir un backup etcd séparé car :
- etcd contient l'état critique du cluster
- Un backup etcd permet une restauration plus rapide
- Velero dépend de Kubernetes, qui dépend d'etcd


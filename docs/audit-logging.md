# 📋 Audit Logging - Guide complet

## Vue d'ensemble

L'audit logging permet de tracer toutes les actions effectuées sur le cluster Kubernetes.
C'est essentiel pour:
- La conformité (RGPD, SOC2, etc.)
- La détection d'intrusions
- L'investigation post-incident

## 🔧 Configuration avec Kubespray

L'audit logging est configuré au niveau du kube-apiserver via Kubespray.

### Activer l'audit logging

Dans votre fichier d'inventaire Kubespray (`inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml`):

```yaml
# Activer l'audit logging
kubernetes_audit: true
audit_log_path: "/var/log/kubernetes/audit/kube-apiserver-audit.log"
audit_log_maxage: 30
audit_log_maxbackups: 10
audit_log_maxsize: 100

# Politique d'audit
audit_policy_file: "{{ kube_config_dir }}/audit-policy.yaml"
```

### Politique d'audit recommandée

Créer le fichier `audit-policy.yaml`:

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Ne pas logger les requêtes de healthcheck
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
      - group: ""
        resources: ["endpoints", "services", "services/status"]
  
  # Ne pas logger les requêtes de kubelet
  - level: None
    users: ["kubelet"]
    verbs: ["get"]
    resources:
      - group: ""
        resources: ["nodes", "nodes/status"]
  
  # Ne pas logger les requêtes read-only sur les configmaps
  - level: None
    resources:
      - group: ""
        resources: ["configmaps"]
        resourceNames: ["kube-root-ca.crt"]
  
  # Logger les modifications de secrets (niveau Metadata uniquement)
  - level: Metadata
    resources:
      - group: ""
        resources: ["secrets"]
  
  # Logger les actions sur les pods
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["pods", "pods/exec", "pods/portforward"]
    verbs: ["create", "update", "patch", "delete"]
  
  # Logger les actions sur les deployments, etc.
  - level: RequestResponse
    resources:
      - group: "apps"
        resources: ["deployments", "statefulsets", "daemonsets"]
    verbs: ["create", "update", "patch", "delete"]
  
  # Logger les modifications RBAC
  - level: RequestResponse
    resources:
      - group: "rbac.authorization.k8s.io"
        resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
  
  # Logger les authentifications
  - level: Metadata
    resources:
      - group: "authentication.k8s.io"
        resources: ["tokenreviews"]
  
  # Niveau par défaut pour tout le reste
  - level: Metadata
    omitStages:
      - "RequestReceived"
```

## 📊 Intégration avec Loki

Les logs d'audit peuvent être collectés par Promtail et envoyés à Loki.

### Configuration Promtail

Ajouter dans la configuration Promtail:

```yaml
scrape_configs:
  - job_name: kubernetes-audit
    static_configs:
      - targets:
          - localhost
        labels:
          job: kubernetes-audit
          __path__: /var/log/kubernetes/audit/*.log
    pipeline_stages:
      - json:
          expressions:
            level: level
            user: user.username
            verb: verb
            resource: objectRef.resource
            namespace: objectRef.namespace
            name: objectRef.name
      - labels:
          level:
          user:
          verb:
          resource:
          namespace:
```

## 🔍 Requêtes Loki utiles

### Toutes les actions de création/suppression
```logql
{job="kubernetes-audit"} |= "create" or |= "delete"
```

### Actions sur les secrets
```logql
{job="kubernetes-audit", resource="secrets"}
```

### Actions par un utilisateur spécifique
```logql
{job="kubernetes-audit", user="admin"}
```

### Actions échouées (403 Forbidden)
```logql
{job="kubernetes-audit"} |= "403" | json | responseStatus_code = 403
```

## 📈 Dashboard Grafana

Créer un dashboard avec les panels suivants:

1. **Nombre d'actions par type** (create, update, delete)
2. **Actions par utilisateur**
3. **Actions par namespace**
4. **Erreurs d'authentification/autorisation**
5. **Timeline des actions sensibles** (secrets, RBAC)

## ⚠️ Recommandations

1. **Rotation des logs**: Configurer une rotation appropriée (maxage, maxsize)
2. **Stockage externe**: Envoyer les logs vers un système externe (Loki, ELK)
3. **Alertes**: Configurer des alertes pour les actions sensibles
4. **Rétention**: Garder les logs d'audit au moins 90 jours
5. **Accès restreint**: Limiter l'accès aux logs d'audit

## 🔐 Actions à auditer en priorité

| Ressource | Actions | Raison |
|-----------|---------|--------|
| Secrets | Toutes | Données sensibles |
| RBAC | Toutes | Changements de permissions |
| Pods/exec | create | Accès aux containers |
| ServiceAccounts | create, delete | Identités |
| NetworkPolicies | Toutes | Sécurité réseau |
| ClusterRoles | Toutes | Permissions globales |


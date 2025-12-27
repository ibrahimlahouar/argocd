# Configuration SMTP Outlook pour AlertManager

## 📧 Informations de connexion

**Email configuré**: `brahi.m99@outlook.fr`  
**Serveur SMTP**: `smtp-mail.outlook.com:587`  
**TLS**: Activé (requis)

---

## 🔐 Comment récupérer le mot de passe

### Option 1 : Utiliser le mot de passe de compte (Simple)

Si vous n'avez **PAS activé la vérification en deux étapes** sur votre compte Outlook :

1. Utilisez directement le **mot de passe** de votre compte Outlook.com
2. C'est le même mot de passe que vous utilisez pour vous connecter à Outlook.com

⚠️ **Attention** : Cette méthode est moins sécurisée. Microsoft recommande d'utiliser un mot de passe d'application.

---

### Option 2 : Créer un mot de passe d'application (Recommandé)

Si vous avez **activé la vérification en deux étapes** (2FA) :

#### Étape 1 : Vérifier que la 2FA est activée

1. Allez sur https://account.microsoft.com/security
2. Connectez-vous avec votre compte `brahi.m99@outlook.fr`
3. Cherchez **"Vérification en deux étapes"** ou **"Two-step verification"**
4. Si c'est désactivé, activez-le d'abord

#### Étape 2 : Créer un mot de passe d'application

1. Allez sur https://account.microsoft.com/security
2. Dans la section **"Sécurité avancée"**, cliquez sur **"Mots de passe d'application"** (App passwords)
3. Cliquez sur **"Créer un nouveau mot de passe d'application"**
4. Donnez-lui un nom descriptif (ex: "Kubernetes AlertManager")
5. Microsoft va générer un mot de passe aléatoire de 16 caractères
6. **COPIEZ CE MOT DE PASSE** (vous ne pourrez plus le voir après)

#### Exemple de mot de passe généré :
```
abcd-efgh-ijkl-mnop
```

⚠️ **Important** : 
- Enlevez les tirets quand vous l'utilisez : `abcdefghijklmnop`
- Ne partagez jamais ce mot de passe
- Vous pouvez en créer plusieurs si besoin

---

## 🔧 Configuration dans AlertManager

### Méthode 1 : Modifier directement le values.yaml (actuel)

Éditez le fichier :
```bash
nano /Users/ilahouar/Documents/argocd/charts/monitoring/values.yaml
```

Ligne 165, remplacez :
```yaml
smtp_auth_password: 'VOTRE_MOT_DE_PASSE_OUTLOOK'
```

Par votre mot de passe (sans tirets si c'est un app password) :
```yaml
smtp_auth_password: 'abcdefghijklmnop'
```

### Méthode 2 : Utiliser un Secret Kubernetes (Recommandé en production)

Pour plus de sécurité, créez un Secret :

```bash
kubectl create secret generic alertmanager-smtp-secret \
  -n monitoring \
  --from-literal=smtp_password='VOTRE_MOT_DE_PASSE'
```

Puis modifiez le `values.yaml` pour référencer le secret au lieu du mot de passe en clair.

---

## 📝 Tester la configuration

Après avoir mis à jour le mot de passe :

```bash
# 1. Commiter les changements
cd /Users/ilahouar/Documents/argocd
git add charts/monitoring/values.yaml
git commit -m "feat: Update AlertManager email to brahi.m99@outlook.fr"
git push

# 2. Forcer la synchro ArgoCD
kubectl -n argocd patch application monitoring \
  --type=merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'

# 3. Attendre le redémarrage d'AlertManager
kubectl rollout status statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n monitoring

# 4. Vérifier les logs
kubectl logs -n monitoring statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -f
```

---

## ❓ Problèmes courants

### "535 5.7.3 Authentication unsuccessful"
- Le mot de passe est incorrect
- Vérifiez que vous avez enlevé les tirets
- Si vous utilisez 2FA, vous DEVEZ utiliser un mot de passe d'application

### "554 5.2.0 STOREDRV.Submission.Exception"
- Outlook bloque l'envoi
- Vérifiez que le compte n'est pas limité
- Essayez d'envoyer un email manuellement depuis Outlook.com

### "Connection timeout"
- Vérifiez les Network Policies (ports 587 et 465 doivent être ouverts)
- Actuellement configuré dans `charts/network-policies/templates/01-baseline.yaml`

### Le compte Outlook demande un CAPTCHA
- Si le compte est nouveau ou peu utilisé, Microsoft peut demander une vérification
- Connectez-vous manuellement sur https://outlook.com et validez le CAPTCHA
- Ensuite, réessayez

---

## 🔗 Liens utiles

- **Compte Microsoft Security**: https://account.microsoft.com/security
- **Outlook.com**: https://outlook.com
- **Documentation SMTP Outlook**: https://support.microsoft.com/en-us/office/pop-imap-and-smtp-settings-8361e398-8af4-4e97-b147-6c6c4ac95353

---

## 📊 Configuration actuelle

```yaml
SMTP Host: smtp-mail.outlook.com
SMTP Port: 587
From: brahi.m99@outlook.fr
To: brahi.m99@outlook.fr
Auth Username: brahi.m99@outlook.fr
Auth Password: À configurer
TLS: Enabled (STARTTLS)
```

---

## ✅ Checklist finale

- [ ] Vérifier que le compte Outlook est actif
- [ ] Activer la 2FA (recommandé)
- [ ] Créer un mot de passe d'application
- [ ] Copier le mot de passe sans les tirets
- [ ] Mettre à jour le `values.yaml` ligne 165
- [ ] Commiter et pusher les changements
- [ ] Synchro ArgoCD
- [ ] Tester en déclenchant une alerte

---

**Date de configuration**: 26 décembre 2025  
**Environnement**: Data Platform Production


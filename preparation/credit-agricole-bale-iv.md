# Préparation Entretien – Projet Bâle IV (Crédit Agricole CIB)

## 1. Pitch court (≈ 2 min)

Bonjour, je m’appelle **Ibrahim**.

Aujourd’hui je suis **DataOps / Big Data Engineer**, avec une première partie de carrière en **développement full‑stack Java / Angular**, puis une spécialisation sur l’écosystème **Big Data et Kubernetes**.

Ma mission actuelle est chez **Crédit Agricole CIB**, sur le **projet Bâle IV**, un système critique qui répond aux obligations réglementaires de la **Banque Centrale Européenne** pour le **calcul des risques de marché**.
Ce système agrège, transforme et restitue de très grands volumes de données financières (marchés, référentiels, valorisations, PnL…) pour produire les rapports réglementaires.

Dans Bâle IV, il y a trois sous‑projets : **Acquisition**, **Calcul** et **Distribution**.
Moi, j’ai travaillé principalement sur la partie **Calcul / Distribution**, qui consomme les résultats du calcul pour **générer les rapports** et appliquer, si besoin, des règles de **transformation et d’agrégation**.

Concrètement, j’ai :
- **Implémenté et optimisé des jobs Spark sur Kubernetes** (tuning, partitionnement, configuration) pour tenir les SLAs de calcul sur de gros volumes ;
- **Créé et optimisé des workflows avec Argo Workflows** pour orchestrer les traitements de calcul et de distribution ;
- Assuré le **support N2/N3** en production : analyse d’incidents, investigation sur Spark et Spring Boot, avec **Dynatrace, Grafana, Kibana** ;
- Mis en place le **déploiement GitOps via ArgoCD** et des **pipelines CI/CD GitLab** (build, tests, déploiement, gestion de tags, GitFlow) ;
- Utilisé **Jupyter Notebook** pour investiguer les données, déboguer et faire des POC techniques.

En résumé, j’étais au croisement entre **performance des traitements Spark**, **fiabilité en production** et **industrialisation des déploiements sur Kubernetes**.

---

## 2. Version détaillée

### 2.1 Contexte & enjeux

Le projet **Bâle IV** chez **Crédit Agricole CIB** est un système critique qui répond aux exigences de la **Banque Centrale Européenne** pour le **calcul des risques de marché**.

Objectif : **collecter, transformer et restituer** de très grands volumes de données financières (marchés, référentiels, valorisations, PnL, etc.) pour produire les rapports réglementaires.

Le projet est découpé en trois sous‑projets :
- **Acquisition** des données ;
- **Calcul** ;
- **Distribution** des résultats vers les différents métiers / entités.

Mon périmètre était principalement **Calcul & Distribution**.

### 2.2 Rôle et responsabilités

Rôle : **DataOps / Big Data Engineer** sur la partie calcul et distribution des rapports, avec un focus sur :
- la **performance et la fiabilité des jobs Spark** sur Kubernetes ;
- l’**industrialisation des workflows** (Argo Workflows, ArgoCD) ;
- le **support de production N2/N3**.

### 2.3 Actions clés

#### Jobs Spark sur Kubernetes
- Développement et optimisation de **jobs Spark (Java & PySpark)** pour traiter de gros volumes de données financières ;
- **Tuning Spark** (partitionnement, parallélisme, mémoire, configuration des exécuteurs) pour respecter les fenêtres de traitement ;
- Adaptation des jobs pour tourner proprement dans un **cluster Kubernetes** (ressources, configuration, logs).

#### Workflows & orchestration
- **Création et optimisation de workflows Argo Workflows** pour orchestrer les différentes étapes : calcul, post‑traitements, distribution des rapports ;
- Gestion des dépendances entre jobs, reprise sur erreur, notifications.

#### GitOps & CI/CD
- **Déploiements en mode GitOps avec ArgoCD** : templates (Helm / manifests) pour déployer les applications Spark et Spring Boot sur Kubernetes ;
- **Pipelines GitLab CI/CD** : build, tests, qualité, déploiement automatique par environnement, gestion des tags et stratégie GitFlow ;
- Création de **templates de déploiement réutilisables**, y compris pour des applications utilisant **Trino** sur Kubernetes.

#### Support N2/N3 & observabilité
- Support **niveau 2 / 3** en production : analyse des incidents, correction de bugs sur les applications Spark et Spring Boot ;
- Utilisation de **Dynatrace, Grafana, Kibana** pour diagnostiquer les lenteurs, analyser les erreurs applicatives et suivre la santé des workflows ;
- Collaboration avec les équipes métier pour **valider les résultats** et sécuriser les mises en production.

#### Data investigation & POCs
- Utilisation de **Jupyter Notebook** pour :
  - analyser des jeux de données complexes ;
  - reproduire / comprendre des anomalies remontées par les métiers ;
  - tester des approches techniques (POC) avant industrialisation.

#### Documentation & collaboration
- **Rédaction et mise à jour de la documentation technique** et des guides d’exploitation ;
- Travail en mode **Agile / Scrum** avec les équipes métiers et les autres équipes IT.

### 2.4 Environnement technique

**Kubernetes (K9s), Spark (Java & PySpark), Spring Boot, Argo Workflows, ArgoCD, Oracle, Dynatrace, Grafana, Kibana, Jupyter, GitLab, GitLab CI/CD, Jira, Agile (Scrum).**


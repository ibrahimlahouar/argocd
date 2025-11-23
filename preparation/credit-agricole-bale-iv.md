## Préparation Entretien – Projet Bâle IV (Crédit Agricole CIB) – Pitch orienté mission BNP (Trino / K8s / GitOps)

### 1. Pitch à dire (≈ 1 min 30)

> Bonjour, je suis Ibrahim.
> Je suis DataOps, avec un background de développeur Java / Angular.
> Ma mission actuelle est chez Crédit Agricole CIB, sur le projet Bâle IV.
> C’est un système critique qui répond aux exigences de la Banque Centrale Européenne pour le calcul des risques de marché.

> Le projet Bâle IV est composé de trois sous‑projets : Acquisition, Calcul et Distribution.
> Moi, je travaille principalement sur la partie Calcul et Distribution.
>
> Au début, j’ai rejoint l’équipe Calcul et j’ai surtout travaillé sur l’implémentation de nouveaux jobs Spark.
>
> Mon rôle, c’était de développer ces traitements et de les optimiser, toute la partie code (tuning, cache..) + adaptation  des configurations de déploiement dans ArgoCD pour nos applications Spark (workers + master).
>
> Ensuite, on a lancé le troisième sous‑projet, Distribution, que l’on a démarré from scratch avec une petite équipe de trois personnes.
>
> L’objectif de ce projet, c’était de distribuer les données vers un stockage S3 et vers une base de données, pour que les différentes entités de CACIB puissent consommer ces données facilement.
> Sur cette partie, j'ai travaile sur la configuration et de la création des charts Helm, ainsi que de l’intégration dans ArgoCD pour automatiser le déploiement de cette nouvelle application.
>
> À ce moment‑là, on a eu un problème de performance : on traitait un gros volume de données chaque jour et l’écriture dans Oracle était trop lente.
>
> Avec l’architecte, on a décidé de mettre en place une couche Trino, en stockant les données au format Iceberg, pour réduire la charge sur Oracle et améliorer les temps de traitement.
>
> C’est pour ça qu’on a collaboré avec l’entité CAGIP, qui offre les sevices Big Data du groupe.
>
> Ils nous ont réservé un namespace dédié pour Trino, afin qu’on puisse déployer trino sur leur infra.
>
>
> * Apache Spark: Traitement
> * Jupyter Notebooks: Exploration
> * Kubernetes: Orchestration
>
> * K9s: Supervision
> * Argo Workflows: Workflows
> * ArgoCD: GitOps
>
> * Oracle Database: Relationnel
> * S3 MinIO: Objet
>
> * Spring Boot: APIs
> * Liquibase: Migrations
> * Grafana: Dashboards
> * Prometheus: Metrics
> * Dynatrace: APM

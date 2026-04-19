# Diagramme de flux de données

Flux complet des données au sein de la plateforme HealthAI Coach.

---

## Vue d'ensemble

```mermaid
flowchart TD
    subgraph Sources["📁 Sources de données (Kaggle / GitHub)"]
        CSV1["daily_food_nutrition_dataset.csv"]
        CSV2["diet_recommendations_dataset.csv"]
        CSV3["gym_members_exercise_tracking.csv"]
        JSON1["exercises.json"]
    end

    subgraph ETL["⚙️ healthai-etl (Python 3.12 · FastAPI · SQLAlchemy)"]
        direction TB
        UP["POST /upload\n(fichier depuis admin)"]
        RUN["POST /run-all\n(pipeline complet)"]
        EXTRACT["Extract\nLecture CSV/JSON\nPandas"]
        TRANSFORM["Transform\nNettoyage · Normalisation\nDétection anomalies"]
        LOAD_OK["Load — lignes valides\nINSERT INTO table"]
        LOAD_KO["Load — lignes anomalies\nINSERT INTO table_import_anomalies"]
        LOG["etl_log\n(nb lignes, statut, message)"]
    end

    subgraph DB["🗄️ PostgreSQL 15 (healthai_db)"]
        direction TB
        REF["Référentiels\nutilisateur · profil_sante\naliment · exercice"]
        LOGS_TBL["Logs utilisateur\nlog_aliment · log_seance · log_sante"]
        DS["Datasets ETL\ndataset_recommendations_regime\ndataset_historique_seance_exercice"]
        ANOM["Tables anomalies\n*_import_anomalies ×6"]
        ETL_CFG["Config ETL\netl_pipeline · etl_column_mapping\netl_log"]
    end

    subgraph API["🔌 healthai-api (NestJS · TypeORM)"]
        CRUD["CRUD REST\n/aliments · /exercices\n/utilisateurs · /logs-*\n/datasets/*"]
        AUTH["Auth\nPOST /auth/login → JWT"]
        HEALTH["GET /health"]
        SWAGGER["Swagger /doc"]
    end

    subgraph ADMIN["🖥️ healthai-admin (Next.js · App Router)"]
        DASH["Dashboard KPIs"]
        VALID["Validation anomalies\nCorrection · Approbation"]
        ETL_UI["Monitoring ETL\nLancer pipeline · Voir logs"]
        META_FRAME["Metabase (iframe)"]
    end

    subgraph ANALYTICS["📊 Metabase"]
        CHARTS["Dashboards analytics\nNutrition · Fitness · Santé"]
    end

    subgraph IAM["🔐 ZITADEL (OIDC)"]
        ZITADEL_SRV["Authentification\nUtilisateurs admin\nService account ETL"]
    end

    %% Flux ETL
    CSV1 & CSV2 & CSV3 & JSON1 --> EXTRACT
    UP --> EXTRACT
    RUN --> EXTRACT
    EXTRACT --> TRANSFORM
    TRANSFORM --> LOAD_OK
    TRANSFORM --> LOAD_KO
    LOAD_OK --> DS
    LOAD_OK --> REF
    LOAD_KO --> ANOM
    TRANSFORM --> LOG
    LOG --> ETL_CFG

    %% Flux API
    REF & LOGS_TBL & DS --> CRUD
    CRUD --> API

    %% Flux Admin
    API --> DASH
    API --> VALID
    ANOM --> VALID
    ETL_CFG --> ETL_UI
    ETL_UI --> RUN

    %% Metabase
    DB --> ANALYTICS
    ANALYTICS --> META_FRAME

    %% Auth
    ZITADEL_SRV --> ADMIN
    ZITADEL_SRV --> ETL

    style Sources fill:#f5f5f5,stroke:#999
    style ETL fill:#e8f4fd,stroke:#2196F3
    style DB fill:#e8f5e9,stroke:#4CAF50
    style API fill:#fff3e0,stroke:#FF9800
    style ADMIN fill:#fce4ec,stroke:#E91E63
    style ANALYTICS fill:#f3e5f5,stroke:#9C27B0
    style IAM fill:#e0f2f1,stroke:#009688
```

---

## Flux détaillé par étape

### 1. Ingestion (ETL)

| Fichier source | Table cible | Lignes importées |
|---------------|-------------|-----------------|
| `daily_food_nutrition_dataset.csv` | `aliment` | ~1 294 |
| `diet_recommendations_dataset.csv` | `dataset_recommendations_regime` | 1 000 |
| `gym_members_exercise_tracking.csv` | `dataset_historique_seance_exercice` | 7 194 |
| `exercises.json` | `exercice` | 873 |

### 2. Transformation & qualité

- **Nettoyage** : suppression doublons, normalisation casse, conversion types
- **Validation** : vérification plages (âge 0-150, poids 0-999kg, BPM 0-300...)
- **Routage** : ligne valide → table production | ligne anomalie → `*_import_anomalies`
- **Traçabilité** : chaque run crée une entrée `etl_log` (nb lignes, statut, durée)

### 3. Exposition API

- Toutes les routes protégées par `x-api-key` + `x-client-id`
- Routes utilisateur protégées par JWT (`Authorization: Bearer`)
- Swagger interactif sur `/doc`

### 4. Validation des anomalies (Admin)

```
Admin liste les anomalies (GET /datasets/*?status=anomalie)
    ↓
Correction manuelle (PATCH /datasets/:id)
    ↓
Validation (POST /datasets/:id/validate) → status = 'validated'
  ou Rejet  (POST /datasets/:id/reject)  → status = 'rejected'
```

### 5. Analytics (Metabase)

Metabase se connecte **directement à PostgreSQL** en lecture seule.  
Les dashboards affichent les données en temps réel sans passer par l'API.

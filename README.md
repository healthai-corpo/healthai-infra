# healthai-infra

Dépôt d'orchestration central pour la plateforme HealthAI.  
Les images sont buildées dans leurs propres pipelines CI et publiées sur GitHub Container Registry (`ghcr.io`). Ce dépôt les assemble via Docker Compose et **centralise la gestion du schéma de base de données**.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Docker network: internal                     │
│                                                                     │
│  healthai-admin (:3000) ──►                                         │
│                              healthai-api (:3001)  ──► db (:5432)  │
│  healthai-web   (:3000) ──►      │                      ▲           │
│                              zitadel (:8080)       db-migrator      │
│                                  │                                  │
│                          postgres-zitadel (internal)                │
│                                                                     │
│  healthai-etl (no port) ──► db + zitadel M2M                        │
│  metabase      (:3002)  ──► db                                      │
└─────────────────────────────────────────────────────────────────────┘
```

| Service              | Image                                       | Port  | Description                        |
|----------------------|---------------------------------------------|-------|------------------------------------|
| `postgres-zitadel`   | `postgres:16-alpine`                        | —     | Base ZITADEL (IAM)                 |
| `zitadel-init`       | `ghcr.io/zitadel/zitadel:latest`            | —     | Init schéma ZITADEL (one-shot)     |
| `zitadel`            | `ghcr.io/zitadel/zitadel:latest`            | 8080  | Identity & access management       |
| `db`                 | `postgres:15-alpine`                        | —     | Base applicative HealthAI          |
| `db-migrator`        | `migrate/migrate:latest`                    | —     | Migrations SQL (one-shot)          |
| `healthai-api`       | `ghcr.io/healthai-corpo/healthai-api`       | 3001  | Backend REST API                   |
| `healthai-etl`       | `ghcr.io/healthai-corpo/healthai-etl`       | —     | Pipeline ETL + endpoint upload     |
| `healthai-admin`     | `ghcr.io/healthai-corpo/healthai-admin`     | 3000  | Dashboard CRUD (interne)           |
| `healthai-web`       | `ghcr.io/healthai-corpo/healthai-web`       | 3000  | Portail client (M3+)               |
| `metabase`           | `metabase/metabase:latest`                  | 3002  | Dashboards analytics               |
| `adminer`            | `adminer:latest`                            | 8081  | Inspection DB (dev/démo)           |

---

## Gestion du schéma de base de données

**Ce dépôt est l'unique source de vérité pour le schéma.**  
Ni TypeORM ni Alembic ne créent ou modifient les tables — ils sont en lecture seule.

Les migrations sont gérées par [golang-migrate](https://github.com/golang-migrate/migrate) via des fichiers SQL versionnés :

```
db/migrations/
├── 000001_initial.up.sql     ← schéma complet (21 tables)
├── 000001_initial.down.sql   ← rollback complet
├── 000002_seeds.up.sql       ← données de démo
└── 000002_seeds.down.sql     ← rollback seeds
```

### Ajouter une migration

```bash
# 1. Créer les fichiers (incrémenter le numéro)
touch db/migrations/000003_description.up.sql
touch db/migrations/000003_description.down.sql

# 2. Écrire le SQL dans chaque fichier

# 3. PR sur healthai-infra → branche feat/migration-description
# 4. Après merge : PR sur healthai-etl (models.py) + healthai-api (entités)
```

---

## Démarrage rapide

### 1. Cloner et configurer

```bash
git clone https://github.com/HealthAI-Corpo/healthai-infra.git
cd healthai-infra
cp .env.example .env
# Remplir toutes les valeurs dans .env
```

### 2. Déployer (images GHCR)

```bash
./scripts/deploy.sh
# ou manuellement :
docker compose pull
docker compose up -d
```

### 3. Développement local (build depuis les sources)

```bash
cp docker-compose.override.yml.example docker-compose.override.yml
# Les repos doivent être clonés dans le dossier parent :
#   ../healthai-api/  ../healthai-admin/  ../healthai-etl/
docker compose up --build -d
```

---

## Variables d'environnement

| Variable                  | Description                                          | Générer avec                  |
|---------------------------|------------------------------------------------------|-------------------------------|
| `POSTGRES_ZITADEL_PASSWORD` | Mot de passe PostgreSQL ZITADEL                    | `openssl rand -base64 32`     |
| `ZITADEL_MASTERKEY`       | Clé maître ZITADEL (≥ 32 chars)                      | `openssl rand -base64 32`     |
| `ZITADEL_HOST`            | Host public ZITADEL (`localhost` en dev)             | —                             |
| `POSTGRES_USER`           | User PostgreSQL app (défaut : `healthai`)            | —                             |
| `POSTGRES_PASSWORD`       | Mot de passe PostgreSQL app                          | `openssl rand -base64 32`     |
| `POSTGRES_DB`             | Nom de la base app (défaut : `healthai_db`)          | —                             |
| `PUBLIC_API_URL`          | URL publique de l'API (navigateur)                   | `https://api.example.com`     |
| `PUBLIC_ZITADEL_URL`      | URL publique ZITADEL (navigateur)                    | `https://auth.example.com`    |
| `PUBLIC_ETL_URL`          | URL publique ETL (navigateur)                        | `https://etl.example.com`     |
| `ETL_CLIENT_ID`           | Client ID M2M ZITADEL pour l'ETL                     | Console ZITADEL               |
| `ETL_CLIENT_SECRET`       | Client secret M2M ZITADEL pour l'ETL                 | Console ZITADEL               |
| `API_TAG` / `ETL_TAG` / `ADMIN_TAG` / `WEB_TAG` | Tags des images GHCR       | `latest` ou SHA de commit     |

---

## Reverse proxy (Caddy)

Un `Caddyfile` est fourni dans `reverse-proxy/`. Caddy gère le TLS automatiquement via Let's Encrypt en production.

---

## Structure du dépôt

```
healthai-infra/
├── docker-compose.yml                  # Compose principal
├── docker-compose.override.yml.example # Template dev local
├── .env.example                        # Template variables
├── .gitignore
├── db/
│   ├── init.sql                        # Référence lisible (non monté)
│   ├── seeds.sql                       # Référence lisible (non montée)
│   └── migrations/                     # ← Migrations actives
│       ├── 000001_initial.up.sql
│       ├── 000001_initial.down.sql
│       ├── 000002_seeds.up.sql
│       └── 000002_seeds.down.sql
├── reverse-proxy/
│   └── Caddyfile
└── scripts/
    └── deploy.sh
```

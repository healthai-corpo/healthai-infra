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
│  healthai-etl (:8000)   ──► db + zitadel M2M                        │
│  metabase      (:3002)  ──► db                                      │
└─────────────────────────────────────────────────────────────────────┘
```

| Service              | Image                                       | Port  | Description                        |
|----------------------|---------------------------------------------|-------|------------------------------------|
| `postgres-zitadel`   | `postgres:16-alpine`                        | —     | Base ZITADEL (IAM)                 |
| `zitadel-init`       | `ghcr.io/zitadel/zitadel:v2.67.5`           | —     | Init schéma ZITADEL (one-shot)     |
| `zitadel`            | `ghcr.io/zitadel/zitadel:v2.67.5`           | 8080  | Identity & access management       |
| `db`                 | `postgres:15-alpine`                        | —     | Base applicative HealthAI          |
| `db-migrator`        | `migrate/migrate:latest`                    | —     | Migrations SQL (one-shot)          |
| `healthai-api`       | `ghcr.io/healthai-corpo/healthai-api`       | 3001  | Backend REST API                   |
| `healthai-etl`       | `ghcr.io/healthai-corpo/healthai-etl`       | 8000  | Pipeline ETL + endpoint upload     |
| `healthai-admin`     | `ghcr.io/healthai-corpo/healthai-admin`     | 3000  | Dashboard CRUD (interne)           |
| `healthai-web`       | `ghcr.io/healthai-corpo/healthai-web`       | 3000  | Portail client (M3+, profil `web`) |
| `metabase`           | `metabase/metabase:latest`                  | 3002  | Dashboards analytics               |
| `adminer`            | `adminer:latest`                            | 8081  | Inspection DB (dev/démo)           |
| `prometheus`         | `prom/prometheus:latest`                    | 9090  | Métriques API                      |

---

## Guide de déploiement

### Prérequis

| Outil | Version minimale | Vérification |
|-------|-----------------|--------------|
| Docker Desktop | 24+ | `docker --version` |
| Docker Compose | v2.20+ | `docker compose version` |
| Git | 2.x | `git --version` |
| RAM disponible | 8 Go | — |

> **Windows** : Docker Desktop doit tourner avec WSL 2 ou Hyper-V activé.

---

### Étape 1 — Cloner le dépôt

```bash
git clone https://github.com/HealthAI-Corpo/healthai-infra.git
cd healthai-infra
```

---

### Étape 2 — Configurer les variables d'environnement

```bash
cp .env.example .env
```

Ouvrir `.env` et remplir **toutes** les valeurs marquées `change_me` :

```bash
# Générer les secrets (Linux / macOS / WSL)
openssl rand -hex 32   # pour POSTGRES_ZITADEL_PASSWORD, POSTGRES_PASSWORD, API_KEY, JWT_SECRET, AUTH_SECRET

# ZITADEL_MASTERKEY doit faire exactement 32 caractères :
node -e "console.log(require('crypto').randomBytes(16).toString('hex'))"
```

Variables **obligatoires** à renseigner avant le premier démarrage :

| Variable | Description |
|----------|-------------|
| `POSTGRES_ZITADEL_PASSWORD` | Mot de passe PostgreSQL ZITADEL |
| `ZITADEL_MASTERKEY` | Clé maître ZITADEL (exactement 32 chars) |
| `POSTGRES_PASSWORD` | Mot de passe PostgreSQL applicatif |
| `API_KEY` | Clé API partagée NestJS ↔ Admin |
| `JWT_SECRET` | Secret de signature des JWT |
| `AUTH_SECRET` | Secret next-auth (admin) |

> Les variables `ADMIN_ZITADEL_CLIENT_ID`, `ADMIN_ZITADEL_CLIENT_SECRET`, `ETL_CLIENT_ID`, `ETL_CLIENT_SECRET` seront remplies **après** la configuration ZITADEL (étape 4).

---

### Étape 3 — Premier démarrage

```bash
docker compose up -d
```

Docker va :
1. Démarrer PostgreSQL (ZITADEL + app)
2. Initialiser le schéma ZITADEL (`zitadel-init` → exit 0)
3. Démarrer ZITADEL sur le port 8080
4. Appliquer les migrations SQL via `db-migrator` (golang-migrate)
5. Démarrer l'API NestJS, l'ETL FastAPI, l'admin Next.js, Metabase

Vérifier que tout est `healthy` / `running` :

```bash
docker compose ps
```

Attendre que `healthai-api` et `healthai-admin` passent en `running` (environ 60–90 secondes).

---

### Étape 4 — Configurer ZITADEL

#### 4.1 — Premier login ZITADEL

Ouvrir [http://localhost:8080](http://localhost:8080).

Identifiants par défaut (générés au premier démarrage) :
- **Login** : `zitadel-admin@zitadel.localhost`
- **Password** : `Password1!`

> Changer le mot de passe au premier login.

#### 4.2 — Créer un projet

Dans la console ZITADEL :
1. **Projects** → **New Project**
2. Nom : `HealthAI`
3. Laisser les options par défaut → **Create**

#### 4.3 — Créer l'application Web (admin dashboard)

Dans le projet `HealthAI` :
1. **Applications** → **New App**
2. Nom : `healthai-admin-front` — Type : **Web**
3. Authentication method : **PKCE**
4. Redirect URI : `http://localhost:3000/api/auth/callback/zitadel`
5. Post Logout URI : `http://localhost:3000`
6. **Create** → noter le **Client ID** (il n'y a pas de secret pour PKCE)

> Si l'application demande un secret (Code flow) : noter **Client ID** et **Client Secret**.

Renseigner dans `.env` :
```env
ADMIN_ZITADEL_CLIENT_ID=<client_id_récupéré>
ADMIN_ZITADEL_CLIENT_SECRET=<client_secret_si_présent>
```

#### 4.4 — Créer le service account ETL (M2M)

Dans la console ZITADEL :
1. **Service Users** → **New Service User**
2. Nom d'utilisateur : `healthai-etl`
3. Authentication method : **Client Credentials (JWT)** ou **Basic**
4. **Create** → **Generate New Client Secret**
5. Noter **Client ID** et **Client Secret**

Renseigner dans `.env` :
```env
ETL_CLIENT_ID=<client_id_etl>
ETL_CLIENT_SECRET=<client_secret_etl>
```

#### 4.5 — Créer un compte utilisateur admin

Dans la console ZITADEL :
1. **Users** → **New User**
2. Remplir prénom, nom, email
3. **Set initial password**

Cet utilisateur servira à se connecter sur le dashboard admin.

#### 4.6 — Redémarrer les services avec les nouvelles credentials

```bash
docker compose up -d healthai-admin healthai-etl
```

---

### Étape 5 — Lancer le pipeline ETL (premier import)

Une fois les services démarrés, déclencher le pipeline pour peupler la base :

```bash
curl -X POST http://localhost:8000/run-all
```

Ou depuis le dashboard admin : **ETL** → **Lancer le pipeline**.

Le pipeline importe :
- `daily_food_nutrition_dataset.csv` → table `dataset_aliment`
- `diet_recommendations_dataset.csv` → table `dataset_recommendations_regime`
- `gym_members_exercise_tracking.csv` → table `dataset_historique_seance_exercice`
- `exercises.json` → table `dataset_exercice`

Vérifier les logs ETL :

```bash
docker compose logs healthai-etl --tail=50
```

---

### Étape 6 — Vérifier les services

| Service | URL | Credentials |
|---------|-----|-------------|
| Dashboard admin | [http://localhost:3000](http://localhost:3000) | Compte ZITADEL créé à l'étape 4.5 |
| API REST + Swagger | [http://localhost:3001/doc](http://localhost:3001/doc) | — |
| ETL API | [http://localhost:8000/docs](http://localhost:8000/docs) | — |
| ZITADEL Console | [http://localhost:8080](http://localhost:8080) | `zitadel-admin@zitadel.localhost` |
| Metabase | [http://localhost:3002](http://localhost:3002) | Setup au premier accès |
| Adminer (DB) | [http://localhost:8081](http://localhost:8081) | Voir `.env` `POSTGRES_*` |
| Prometheus | [http://localhost:9090](http://localhost:9090) | — |

**Connexion Adminer** :
- Système : `PostgreSQL`
- Serveur : `db`
- Utilisateur : valeur de `POSTGRES_USER` (défaut : `healthai`)
- Mot de passe : valeur de `POSTGRES_PASSWORD`
- Base : valeur de `POSTGRES_DB` (défaut : `healthai_db`)

---

### Développement local (build depuis les sources)

Pour builder les images localement plutôt que de les puller depuis GHCR :

```bash
# Cloner tous les repos dans le même dossier parent
cd ..
git clone https://github.com/HealthAI-Corpo/healthai-api.git
git clone https://github.com/HealthAI-Corpo/healthai-admin.git
git clone https://github.com/HealthAI-Corpo/healthai-etl.git
cd healthai-infra

# Activer la surcharge locale
cp docker-compose.override.yml.example docker-compose.override.yml

# Build et démarrage
docker compose up --build -d
```

Le fichier `docker-compose.override.yml` redirige le build vers les sources locales.

---

## Gestion du schéma de base de données

**Ce dépôt est l'unique source de vérité pour le schéma.**  
Ni TypeORM ni Alembic ne créent ou modifient les tables — ils sont en lecture seule.

Les migrations sont gérées par [golang-migrate](https://github.com/golang-migrate/migrate) via des fichiers SQL versionnés :

```
db/migrations/
├── 000001_initial.up.sql              ← schéma complet (21 tables)
├── 000001_initial.down.sql
├── 000002_seeds.up.sql                ← données de démo
├── 000002_seeds.down.sql
├── 000003_fix_etl_schema.up.sql       ← correctifs colonnes ETL
├── 000004_fix_numeric_types.up.sql    ← types NUMERIC corrigés
└── 000005_fix_adherence_overflow.up.sql
```

### Ajouter une migration

```bash
# 1. Créer les fichiers (incrémenter le numéro)
touch db/migrations/000006_description.up.sql
touch db/migrations/000006_description.down.sql

# 2. Écrire le SQL dans chaque fichier

# 3. PR sur healthai-infra → branche feat/migration-description
# 4. Après merge : PR sur healthai-etl (models.py) + healthai-api (entités)
```

---

## Variables d'environnement

| Variable | Description | Générer avec |
|----------|-------------|--------------|
| `POSTGRES_ZITADEL_PASSWORD` | Mot de passe PostgreSQL ZITADEL | `openssl rand -hex 32` |
| `ZITADEL_MASTERKEY` | Clé maître ZITADEL (32 chars) | `node -e "..."` (voir étape 2) |
| `POSTGRES_USER` | User PostgreSQL app (défaut : `healthai`) | — |
| `POSTGRES_PASSWORD` | Mot de passe PostgreSQL app | `openssl rand -hex 32` |
| `POSTGRES_DB` | Nom de la base (défaut : `healthai_db`) | — |
| `API_KEY` | Clé partagée API ↔ Admin | `openssl rand -hex 32` |
| `JWT_SECRET` | Secret JWT NestJS | `openssl rand -hex 32` |
| `AUTH_SECRET` | Secret next-auth | `openssl rand -base64 32` |
| `ADMIN_ZITADEL_CLIENT_ID` | Client ID app Web ZITADEL | Console ZITADEL |
| `ADMIN_ZITADEL_CLIENT_SECRET` | Client secret app Web | Console ZITADEL |
| `ETL_CLIENT_ID` | Client ID service account ETL | Console ZITADEL |
| `ETL_CLIENT_SECRET` | Client secret service account ETL | Console ZITADEL |
| `PUBLIC_API_URL` | URL publique API (navigateur) | `http://localhost:3001` |
| `PUBLIC_ZITADEL_URL` | URL publique ZITADEL | `http://localhost:8080` |
| `API_TAG` / `ETL_TAG` / `ADMIN_TAG` | Tags images GHCR | `latest` |

---

## Résolution des problèmes courants

**Les services ne démarrent pas / restent en `restarting`**
```bash
docker compose logs <service>   # voir les erreurs
docker compose ps               # vérifier l'état des healthchecks
```

**ZITADEL ne répond pas sur localhost:8080**
```bash
docker compose logs zitadel --tail=30
# Attendre 30–60s, ZITADEL prend du temps au premier démarrage
```

**db-migrator échoue (`migration failed`)**
```bash
docker compose logs db-migrator
# Vérifier que POSTGRES_PASSWORD dans .env est correct
# Réinitialiser si nécessaire :
docker compose down -v   # ⚠️ supprime toutes les données
docker compose up -d
```

**L'admin affiche des données fictives (mode mock)**
```bash
# Vérifier que NEXT_PUBLIC_USE_MOCK est bien absent du .env
# ou positionné à false dans docker-compose.override.yml
docker compose logs healthai-admin | grep MOCK
```

**ETL : aucun fichier traité**
```bash
# Vérifier que les CSV sont dans le volume etl_data
docker compose exec healthai-etl ls /app/data/raw/
# Si vide, copier depuis healthai-etl/data/raw/ vers le volume
```

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
│   └── migrations/                     # ← Migrations actives (golang-migrate)
│       ├── 000001_initial.{up,down}.sql
│       ├── 000002_seeds.{up,down}.sql
│       ├── 000003_fix_etl_schema.{up,down}.sql
│       ├── 000004_fix_numeric_types.{up,down}.sql
│       └── 000005_fix_adherence_overflow.{up,down}.sql
├── infra/
│   └── prometheus/prometheus.yml
├── reverse-proxy/
│   └── Caddyfile                       # TLS automatique en production
└── scripts/
    └── deploy.sh                       # Script de déploiement GHCR
```

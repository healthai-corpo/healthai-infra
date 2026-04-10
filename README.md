# healthai-infra

Central orchestration repository for the HealthAI microservices platform.  
All service images are built in their own CI pipelines and pushed to the GitHub Container Registry (`ghcr.io`). This repository pulls those images and wires everything together with Docker Compose.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Docker network: internal              │
│                                                             │
│  healthai-web (:3000) ──► healthai-api (:5000)              │
│                                   │                         │
│                            zitadel (:8080)                  │
│                                   │                         │
│                           postgres (internal)               │
│                                                             │
│  healthai-etl (no port) ──► zitadel (M2M)                   │
└─────────────────────────────────────────────────────────────┘
```

| Service         | Image                                      | Port  | Description                        |
|-----------------|--------------------------------------------|-------|------------------------------------|
| `postgres`      | `postgres:16-alpine`                       | —     | Database for ZITADEL               |
| `zitadel-init`  | `ghcr.io/zitadel/zitadel:latest`           | —     | One-shot DB schema init            |
| `zitadel`       | `ghcr.io/zitadel/zitadel:latest`           | 8080  | Identity & access management       |
| `healthai-api`  | `ghcr.io/healthai-corpo/healthai-api`      | 5000  | Backend REST API                   |
| `healthai-etl`  | `ghcr.io/healthai-corpo/healthai-etl`      | —     | Background ETL pipeline            |
| `healthai-web`  | `ghcr.io/healthai-corpo/healthai-web`      | 3000  | Frontend web application           |

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) ≥ 24 with the Compose plugin
- Access to `ghcr.io/healthai-corpo/*` images (authenticate with `docker login ghcr.io`)

---

## Quick start

### 1. Clone and configure

```bash
git clone https://github.com/HealthAI-Corpo/healthai-infra.git
cd healthai-infra
cp .env.example .env
```

Open `.env` and fill in every value (see [Environment variables](#environment-variables) below).

### 2. Deploy

```bash
./scripts/deploy.sh
```

Or manually:

```bash
docker compose pull
docker compose up -d
```

### 3. Verify

```bash
docker compose ps
docker compose logs -f
```

---

## Environment variables

Copy `.env.example` to `.env` and set the following:

| Variable            | Description                                                   | Example / how to generate          |
|---------------------|---------------------------------------------------------------|------------------------------------|
| `API_TAG`           | Image tag for `healthai-api`                                  | `1.2.3` or `latest`               |
| `ETL_TAG`           | Image tag for `healthai-etl`                                  | `1.2.3` or `latest`               |
| `WEB_TAG`           | Image tag for `healthai-web`                                  | `1.2.3` or `latest`               |
| `POSTGRES_PASSWORD` | Password for the PostgreSQL `zitadel` user                    | `openssl rand -base64 32`          |
| `ZITADEL_MASTERKEY` | 32-byte master key used by ZITADEL to encrypt sensitive data  | `openssl rand -base64 32`          |
| `ETL_CLIENT_ID`     | OAuth2 client ID for the ETL service account (M2M)            | Created in the ZITADEL console     |
| `ETL_CLIENT_SECRET` | OAuth2 client secret for the ETL service account (M2M)        | Created in the ZITADEL console     |

### Generate a secure master key

```bash
openssl rand -base64 32
```

> ⚠️ **Never commit your `.env` file.** It is already listed in `.gitignore`.

---

## Reverse proxy (Caddy)

A sample `Caddyfile` is provided in `reverse-proxy/`. Edit the domain names to match your setup. Caddy handles TLS automatically via Let's Encrypt when deployed with a real domain.

---

## Repository structure

```
healthai-infra/
├── docker-compose.yml      # Main Compose file
├── .env.example            # Template for environment variables
├── README.md               # This file
├── reverse-proxy/
│   └── Caddyfile           # Caddy reverse proxy configuration
└── scripts/
    └── deploy.sh           # Pull images and restart services
```

---

## Updating a service

To roll out a new version of a single service, update its tag in `.env` and re-run the deploy script:

```bash
# Edit .env: set API_TAG=1.3.0
./scripts/deploy.sh
```

---

## License

See individual service repositories for licensing information.

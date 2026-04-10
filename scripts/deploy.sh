#!/usr/bin/env bash
# ==============================================================================
# scripts/deploy.sh — pull the latest images and (re)start all services
# Usage: ./scripts/deploy.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose.yml"

echo "==> Pulling latest images..."
docker compose -f "${COMPOSE_FILE}" pull

echo "==> Starting services in detached mode..."
docker compose -f "${COMPOSE_FILE}" up -d

echo "==> Deployment complete. Running containers:"
docker compose -f "${COMPOSE_FILE}" ps

#!/bin/bash

# PostgreSQL Restore Script for Keycloak Database
# This script restores a pg_dump backup to the Keycloak database
# Usage: ./restore-postgres.sh <backup-file.sql.gz>

set -e

# Configuration
DB_CONTAINER="exp.db.keycloak"
DB_NAME="KeycloakDb"
DB_USER="bale"
DB_PASSWORD="bale"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if backup file is provided
if [ -z "$1" ]; then
    error "Usage: $0 <backup-file.sql.gz>"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    error "Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    error "Container ${DB_CONTAINER} is not running!"
    exit 1
fi

warning "This will DROP and RECREATE the database ${DB_NAME}!"
warning "All current data will be lost!"
read -p "Are you sure you want to continue? (yes/NO): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log "Restore cancelled."
    exit 0
fi

log "Starting restore of ${DB_NAME} database from ${BACKUP_FILE}..."

# Determine if file is compressed
if [[ "${BACKUP_FILE}" == *.gz ]]; then
    log "Decompressing backup file..."
    gunzip -c "${BACKUP_FILE}" | docker exec -i "${DB_CONTAINER}" psql -U "${DB_USER}" -d postgres
else
    log "Restoring backup file..."
    docker exec -i "${DB_CONTAINER}" psql -U "${DB_USER}" -d postgres < "${BACKUP_FILE}"
fi

if [ $? -eq 0 ]; then
    log "Restore completed successfully!"
    log "Database ${DB_NAME} has been restored from ${BACKUP_FILE}"
    exit 0
else
    error "Restore failed!"
    exit 1
fi


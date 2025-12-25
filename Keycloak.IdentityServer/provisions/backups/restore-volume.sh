#!/bin/bash

# Docker Volume Restore Script for exp_postgres_keycloak
# This script restores a volume backup tar archive
# Usage: ./restore-volume.sh <backup-file.tar.gz>

set -e

# Configuration
VOLUME_NAME="exp_postgres_keycloak"
DB_CONTAINER="exp.db.keycloak"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

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
    error "Usage: $0 <backup-file.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    error "Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

warning "This will REPLACE the entire volume ${VOLUME_NAME}!"
warning "All current data will be lost!"
warning "The database container MUST be stopped before restoring!"
read -p "Are you sure you want to continue? (yes/NO): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log "Restore cancelled."
    exit 0
fi

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    error "Container ${DB_CONTAINER} is still running!"
    error "Please stop the container first: docker stop ${DB_CONTAINER}"
    exit 1
fi

log "Starting volume restore of ${VOLUME_NAME} from ${BACKUP_FILE}..."

# Remove existing volume (if it exists)
if docker volume ls --format '{{.Name}}' | grep -q "^${VOLUME_NAME}$"; then
    log "Removing existing volume..."
    docker volume rm "${VOLUME_NAME}" || true
fi

# Create new volume
log "Creating new volume..."
docker volume create "${VOLUME_NAME}"

# Restore backup to volume
log "Restoring backup to volume..."
docker run --rm \
    -v "${VOLUME_NAME}:/data" \
    -v "$(realpath "${BACKUP_FILE}"):/backup/backup.tar.gz:ro" \
    alpine:latest \
    sh -c "cd /data && tar xzf /backup/backup.tar.gz && chmod -R 700 /data"

if [ $? -eq 0 ]; then
    log "Volume restore completed successfully!"
    log "Volume ${VOLUME_NAME} has been restored from ${BACKUP_FILE}"
    log "You can now start the database container: docker start ${DB_CONTAINER}"
    exit 0
else
    error "Restore failed!"
    exit 1
fi


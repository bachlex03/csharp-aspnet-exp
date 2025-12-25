#!/bin/bash

# Docker Volume Backup Script for exp_postgres_keycloak
# This script creates a tar archive of the entire PostgreSQL data directory
# Usage: ./backup-volume.sh [backup-name]

set -e

# Configuration
VOLUME_NAME="exp_postgres_keycloak"
DB_CONTAINER="exp.db.keycloak"
BACKUP_DIR="${BACKUP_DIR:-$(dirname "$0")}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="${1:-keycloak_volume_${TIMESTAMP}}"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

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

# Check if volume exists
if ! docker volume ls --format '{{.Name}}' | grep -q "^${VOLUME_NAME}$"; then
    error "Volume ${VOLUME_NAME} does not exist!"
    exit 1
fi

# Check if container is running (recommended to stop for consistent backup)
if docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    warning "Container ${DB_CONTAINER} is running. For consistent backup, consider stopping it first."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Backup cancelled."
        exit 0
    fi
fi

log "Starting volume backup of ${VOLUME_NAME}..."

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Create a temporary container to access the volume
TEMP_CONTAINER="backup-${VOLUME_NAME}-${TIMESTAMP}"

log "Creating temporary container to access volume..."
docker run --rm \
    -v "${VOLUME_NAME}:/data:ro" \
    -v "${BACKUP_DIR}:/backup" \
    alpine:latest \
    tar czf "/backup/${BACKUP_NAME}.tar.gz" -C /data .

if [ -f "${BACKUP_FILE}" ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    log "Volume backup completed successfully!"
    log "Backup size: ${BACKUP_SIZE}"
    log "Backup saved to: ${BACKUP_FILE}"
    
    # Cleanup old backups
    if [ "${RETENTION_DAYS}" -gt 0 ]; then
        log "Cleaning up backups older than ${RETENTION_DAYS} days..."
        find "${BACKUP_DIR}" -name "keycloak_volume_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
        DELETED_COUNT=$(find "${BACKUP_DIR}" -name "keycloak_volume_*.tar.gz" -type f -mtime +${RETENTION_DAYS} 2>/dev/null | wc -l)
        if [ "${DELETED_COUNT}" -gt 0 ]; then
            log "Deleted ${DELETED_COUNT} old backup(s)"
        fi
    fi
    
    log "Backup process completed successfully!"
    exit 0
else
    error "Backup failed! File not created."
    exit 1
fi


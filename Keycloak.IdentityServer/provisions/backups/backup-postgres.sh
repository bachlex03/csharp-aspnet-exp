#!/bin/bash

# PostgreSQL Backup Script for Keycloak Database
# This script performs pg_dump backup of the Keycloak database
# Usage: ./backup-postgres.sh [backup-name]

set -e

# Configuration
DB_CONTAINER="exp.db.keycloak"
DB_NAME="KeycloakDb"
DB_USER="bale"
DB_PASSWORD="bale"
BACKUP_DIR="${BACKUP_DIR:-$(dirname "$0")}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="${1:-keycloak_backup_${TIMESTAMP}}"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.sql"
BACKUP_FILE_COMPRESSED="${BACKUP_FILE}.gz"
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

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    error "Container ${DB_CONTAINER} is not running!"
    exit 1
fi

log "Starting backup of ${DB_NAME} database..."

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Perform pg_dump backup
log "Executing pg_dump..."
if docker exec "${DB_CONTAINER}" pg_dump \
    -U "${DB_USER}" \
    -d "${DB_NAME}" \
    --clean \
    --if-exists \
    --create \
    --format=plain \
    > "${BACKUP_FILE}" 2>/dev/null; then
    
    log "Backup completed successfully: ${BACKUP_FILE}"
    
    # Compress backup
    log "Compressing backup..."
    gzip -f "${BACKUP_FILE}"
    BACKUP_SIZE=$(du -h "${BACKUP_FILE_COMPRESSED}" | cut -f1)
    log "Compressed backup size: ${BACKUP_SIZE}"
    log "Backup saved to: ${BACKUP_FILE_COMPRESSED}"
    
    # Cleanup old backups
    if [ "${RETENTION_DAYS}" -gt 0 ]; then
        log "Cleaning up backups older than ${RETENTION_DAYS} days..."
        find "${BACKUP_DIR}" -name "keycloak_backup_*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete
        DELETED_COUNT=$(find "${BACKUP_DIR}" -name "keycloak_backup_*.sql.gz" -type f -mtime +${RETENTION_DAYS} 2>/dev/null | wc -l)
        if [ "${DELETED_COUNT}" -gt 0 ]; then
            log "Deleted ${DELETED_COUNT} old backup(s)"
        fi
    fi
    
    log "Backup process completed successfully!"
    exit 0
else
    error "Backup failed!"
    # Cleanup partial backup file if it exists
    [ -f "${BACKUP_FILE}" ] && rm -f "${BACKUP_FILE}"
    exit 1
fi


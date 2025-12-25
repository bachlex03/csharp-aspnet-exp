#!/bin/bash

# Remote Backup Script
# This script performs a backup and optionally copies it to remote storage
# Usage: ./backup-to-remote.sh [s3-bucket|scp-host|local-only]

set -e

# Configuration
BACKUP_SCRIPT_DIR="$(dirname "$0")"
BACKUP_DIR="${BACKUP_DIR:-${BACKUP_SCRIPT_DIR}}"
REMOTE_TYPE="${1:-local-only}"

# Remote storage configurations (set these as environment variables)
S3_BUCKET="${S3_BUCKET:-}"
SCP_HOST="${SCP_HOST:-}"
SCP_USER="${SCP_USER:-}"
SCP_PATH="${SCP_PATH:-/backups/keycloak}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Perform local backup first
log "Performing local backup..."
"${BACKUP_SCRIPT_DIR}/backup-postgres.sh" || {
    error "Local backup failed!"
    exit 1
}

# Find the most recent backup
LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/keycloak_backup_*.sql.gz 2>/dev/null | head -n1)

if [ -z "${LATEST_BACKUP}" ]; then
    error "No backup file found!"
    exit 1
fi

log "Latest backup: ${LATEST_BACKUP}"

# Copy to remote storage based on type
case "${REMOTE_TYPE}" in
    s3)
        if [ -z "${S3_BUCKET}" ]; then
            error "S3_BUCKET environment variable not set!"
            exit 1
        fi
        
        if ! command -v aws &> /dev/null; then
            error "AWS CLI not found. Install it first."
            exit 1
        fi
        
        log "Uploading to S3: s3://${S3_BUCKET}/keycloak/$(basename ${LATEST_BACKUP})"
        aws s3 cp "${LATEST_BACKUP}" "s3://${S3_BUCKET}/keycloak/$(basename ${LATEST_BACKUP})" || {
            error "S3 upload failed!"
            exit 1
        }
        log "Upload to S3 completed successfully!"
        ;;
    
    scp)
        if [ -z "${SCP_HOST}" ] || [ -z "${SCP_USER}" ]; then
            error "SCP_HOST and SCP_USER environment variables must be set!"
            exit 1
        fi
        
        log "Copying to remote server: ${SCP_USER}@${SCP_HOST}:${SCP_PATH}/"
        scp "${LATEST_BACKUP}" "${SCP_USER}@${SCP_HOST}:${SCP_PATH}/" || {
            error "SCP copy failed!"
            exit 1
        }
        log "Copy to remote server completed successfully!"
        ;;
    
    local-only)
        log "Backup completed. Stored locally at: ${LATEST_BACKUP}"
        ;;
    
    *)
        error "Unknown remote type: ${REMOTE_TYPE}"
        error "Supported types: s3, scp, local-only"
        exit 1
        ;;
esac

log "Backup process completed successfully!"


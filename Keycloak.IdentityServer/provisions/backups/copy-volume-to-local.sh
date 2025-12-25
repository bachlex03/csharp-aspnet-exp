#!/bin/bash

# Bash script to copy data from Docker volume to local directory
# Usage: ./copy-volume-to-local.sh

set -e

# Configuration
VOLUME_NAME="${VOLUME_NAME:-exp_postgres_keycloak}"
LOCAL_PATH="${LOCAL_PATH:-../db-data/keycloak}"
DB_CONTAINER="exp.db.keycloak"

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

# Get absolute path
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_PATH="$(cd "$SCRIPT_DIR/$LOCAL_PATH" && pwd 2>/dev/null || echo "$SCRIPT_DIR/$LOCAL_PATH")"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running or not accessible!"
    exit 1
fi

# Check if volume exists
if ! docker volume ls --format '{{.Name}}' | grep -q "^${VOLUME_NAME}$"; then
    error "Volume ${VOLUME_NAME} does not exist!"
    exit 1
fi

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    warning "Container ${DB_CONTAINER} is running. For consistent copy, consider stopping it first."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Copy cancelled."
        exit 0
    fi
fi

# Create local directory if it doesn't exist
if [ ! -d "$LOCAL_PATH" ]; then
    log "Creating local directory: $LOCAL_PATH"
    mkdir -p "$LOCAL_PATH"
else
    warning "Local directory already exists: $LOCAL_PATH"
    read -p "This will overwrite existing data. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Copy cancelled."
        exit 0
    fi
    # Clear existing directory
    log "Clearing existing directory..."
    rm -rf "${LOCAL_PATH:?}"/*
fi

log "Starting copy from volume ${VOLUME_NAME} to ${LOCAL_PATH}..."

# Create a temporary container to copy data
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEMP_CONTAINER="copy-${VOLUME_NAME}-${TIMESTAMP}"

# Use a temporary container with alpine to copy files
log "Creating temporary container to access volume..."

# Extract data from volume to local directory
docker run --rm \
    -v "${VOLUME_NAME}:/data:ro" \
    -v "${LOCAL_PATH}:/backup" \
    alpine:latest \
    sh -c "cd /data && tar czf - ." | tar xzf - -C "$LOCAL_PATH"

if [ $? -eq 0 ]; then
    ITEM_COUNT=$(find "$LOCAL_PATH" -type f | wc -l)
    log "Copy completed successfully!"
    log "Copied to: $LOCAL_PATH"
    log "Files copied: $ITEM_COUNT"
    log ""
    log "Note: On Windows, you may need to adjust file permissions if you plan to use this as a bind mount."
    exit 0
else
    error "Copy failed!"
    exit 1
fi


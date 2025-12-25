# Keycloak PostgreSQL Backup Strategies

This directory contains backup and restore scripts for the `exp_postgres_keycloak` Docker volume and Keycloak database.

## Overview

There are two main backup strategies available:

1. **pg_dump Backup** (Recommended) - Logical backup using PostgreSQL's native tool
2. **Volume Backup** - Physical backup of the entire PostgreSQL data directory

## Backup Strategies

### Strategy 1: pg_dump Backup (Recommended)

**Advantages:**
- ✅ Portable across PostgreSQL versions
- ✅ Smaller backup size (compressed)
- ✅ Can restore to different PostgreSQL versions
- ✅ Can selectively restore specific tables/schemas
- ✅ No need to stop the database container
- ✅ Consistent backup (transaction-safe)

**Disadvantages:**
- ⚠️ Slower for very large databases
- ⚠️ Requires PostgreSQL client tools

**Usage:**
```bash
# Basic backup
./backup-postgres.sh

# Custom backup name
./backup-postgres.sh my_custom_backup

# Set custom backup directory and retention
BACKUP_DIR=/path/to/backups RETENTION_DAYS=60 ./backup-postgres.sh
```

**Restore:**
```bash
./restore-postgres.sh keycloak_backup_20240101_120000.sql.gz
```

### Strategy 2: Volume Backup

**Advantages:**
- ✅ Faster for large databases
- ✅ Complete file-level backup
- ✅ Includes all PostgreSQL configuration

**Disadvantages:**
- ⚠️ Larger backup size
- ⚠️ Requires same PostgreSQL version for restore
- ⚠️ Should stop database for consistent backup
- ⚠️ Less portable

**Usage:**
```bash
# Basic backup (will warn if container is running)
./backup-volume.sh

# Custom backup name
./backup-volume.sh my_volume_backup

# Set custom backup directory and retention
BACKUP_DIR=/path/to/backups RETENTION_DAYS=60 ./backup-volume.sh
```

**Restore:**
```bash
# IMPORTANT: Stop the database container first!
docker stop exp.db.keycloak

# Restore volume
./restore-volume.sh keycloak_volume_20240101_120000.tar.gz

# Start the database container
docker start exp.db.keycloak
```

## Automated Backup Solutions

### Option 1: Cron Job (Linux)

Add to crontab for daily backups at 2 AM:
```bash
# Edit crontab
crontab -e

# Add this line (adjust path as needed)
0 2 * * * /path/to/backup-postgres.sh >> /var/log/keycloak-backup.log 2>&1
```

### Option 2: Systemd Timer (Linux)

Create `/etc/systemd/system/keycloak-backup.service`:
```ini
[Unit]
Description=Keycloak PostgreSQL Backup
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/path/to/backup-postgres.sh
User=your-user
Environment="BACKUP_DIR=/var/backups/keycloak"
Environment="RETENTION_DAYS=30"
```

Create `/etc/systemd/system/keycloak-backup.timer`:
```ini
[Unit]
Description=Run Keycloak Backup Daily
Requires=keycloak-backup.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:
```bash
sudo systemctl enable keycloak-backup.timer
sudo systemctl start keycloak-backup.timer
```

### Option 3: Docker Compose Backup Service

**Using the provided backup service:**

A ready-to-use backup service is available in `docker-compose.backup.yml`:

```bash
# Start with automated backup service
docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.backup.yml up -d

# Configure backup interval (default: 24 hours)
BACKUP_INTERVAL=43200 RETENTION_DAYS=60 docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.backup.yml up -d
```

**Manual addition to docker-compose.yml:**
```yaml
services:
  backup:
    image: postgres:alpine
    container_name: keycloak-backup
    environment:
      - PGPASSWORD=bale
    volumes:
      - ./provisions/backups:/backups
    networks:
      - exp-keycloak-network
    command: >
      sh -c "
        while true; do
          pg_dump -h exp.db.keycloak -U bale -d KeycloakDb --clean --if-exists --create | gzip > /backups/keycloak_backup_$$(date +%Y%m%d_%H%M%S).sql.gz;
          find /backups -name 'keycloak_backup_*.sql.gz' -mtime +30 -delete;
          sleep 86400;
        done
      "
    restart: unless-stopped
```

## Backup Retention

Both scripts support automatic cleanup of old backups using the `RETENTION_DAYS` environment variable:

```bash
# Keep backups for 60 days
RETENTION_DAYS=60 ./backup-postgres.sh
```

Default retention: **30 days**

## Backup Storage Best Practices

1. **Local Storage**: Store backups in `provisions/backups/` (default)
2. **Remote Storage**: Copy backups to remote storage (S3, NFS, etc.)
3. **Offsite Backup**: Regularly copy backups to offsite location
4. **Encryption**: Consider encrypting sensitive backups
5. **Verification**: Periodically test restore procedures

### Example: Copy to Remote Storage

**Using the automated remote backup script:**
```bash
# Backup and upload to S3
S3_BUCKET=my-backup-bucket ./backup-to-remote.sh s3

# Backup and copy via SCP
SCP_HOST=backup-server.com SCP_USER=backupuser SCP_PATH=/backups/keycloak ./backup-to-remote.sh scp

# Local backup only
./backup-to-remote.sh local-only
```

**Manual copy:**
```bash
# After backup, copy to S3
aws s3 cp keycloak_backup_*.sql.gz s3://my-backup-bucket/keycloak/

# Or to remote server
scp keycloak_backup_*.sql.gz user@backup-server:/backups/keycloak/
```

## Monitoring and Alerts

### Check Backup Status

```bash
# List recent backups
ls -lh provisions/backups/

# Check backup integrity
gunzip -t keycloak_backup_*.sql.gz
```

### Backup Verification Script

Create `verify-backup.sh`:
```bash
#!/bin/bash
BACKUP_FILE="$1"
if gunzip -t "$BACKUP_FILE" 2>/dev/null; then
    echo "✓ Backup file is valid"
    echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
    echo "Created: $(stat -c %y "$BACKUP_FILE")"
else
    echo "✗ Backup file is corrupted!"
    exit 1
fi
```

## Disaster Recovery Procedure

1. **Stop services**:
   ```bash
   docker-compose down
   ```

2. **Restore database** (choose one):
   - pg_dump restore: `./restore-postgres.sh backup.sql.gz`
   - Volume restore: `./restore-volume.sh backup.tar.gz` (stop DB first)

3. **Start services**:
   ```bash
   docker-compose up -d
   ```

4. **Verify**:
   - Check Keycloak is accessible
   - Verify data integrity
   - Test authentication flows

## Security Considerations

1. **Backup File Permissions**: Ensure backups are readable only by authorized users
   ```bash
   chmod 600 provisions/backups/*.sql.gz
   ```

2. **Credentials**: Never commit credentials to version control
   - Use environment variables
   - Use Docker secrets
   - Use external secret management

3. **Encryption**: Encrypt backups containing sensitive data
   ```bash
   # Encrypt backup
   gpg --symmetric --cipher-algo AES256 backup.sql.gz
   
   # Decrypt backup
   gpg --decrypt backup.sql.gz.gpg > backup.sql.gz
   ```

## Troubleshooting

### Backup fails with "container not running"
- Ensure `exp.db.keycloak` container is running: `docker ps`

### Backup fails with "permission denied"
- Check script permissions: `chmod +x backup-postgres.sh`
- Check backup directory permissions

### Restore fails with "database does not exist"
- The restore script will create the database automatically
- Ensure you're using the correct backup file format

### Volume restore fails
- Ensure database container is stopped
- Check volume exists: `docker volume ls`
- Verify backup file is not corrupted

## Script Configuration

All scripts support environment variables:

- `BACKUP_DIR`: Custom backup directory (default: script directory)
- `RETENTION_DAYS`: Days to keep backups (default: 30)
- `DB_CONTAINER`: Database container name (default: exp.db.keycloak)
- `DB_NAME`: Database name (default: KeycloakDb)
- `DB_USER`: Database user (default: bale)
- `DB_PASSWORD`: Database password (default: bale)

## Additional Resources

- [PostgreSQL Backup Documentation](https://www.postgresql.org/docs/current/backup.html)
- [Docker Volume Backup Best Practices](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)


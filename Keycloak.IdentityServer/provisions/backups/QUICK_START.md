# Quick Start Guide - Keycloak Backup

## Quick Backup Commands

### 1. Manual Backup (pg_dump - Recommended)
```bash
cd Keycloak.IdentityServer/provisions/backups
./backup-postgres.sh
```

### 2. Manual Backup (Volume)
```bash
cd Keycloak.IdentityServer/provisions/backups
./backup-volume.sh
```

### 3. Restore from Backup
```bash
# Restore pg_dump backup
./restore-postgres.sh keycloak_backup_20240101_120000.sql.gz

# Restore volume backup (stop DB first!)
docker stop exp.db.keycloak
./restore-volume.sh keycloak_volume_20240101_120000.tar.gz
docker start exp.db.keycloak
```

## Automated Backup Setup

### Option A: Cron Job (Daily at 2 AM)
```bash
crontab -e
# Add this line:
0 2 * * * cd /path/to/Keycloak.IdentityServer/provisions/backups && ./backup-postgres.sh >> /var/log/keycloak-backup.log 2>&1
```

### Option B: Docker Compose Service
```bash
# Start with backup service
docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.backup.yml up -d
```

### Option C: Systemd Timer
See main README.md for detailed systemd timer setup.

## Remote Backup

### S3 Backup
```bash
S3_BUCKET=my-backup-bucket ./backup-to-remote.sh s3
```

### SCP Backup
```bash
SCP_HOST=backup-server.com SCP_USER=backupuser ./backup-to-remote.sh scp
```

## Verify Backup
```bash
# List backups
ls -lh provisions/backups/

# Check backup integrity
gunzip -t keycloak_backup_*.sql.gz
```

## Important Notes

1. **pg_dump** is recommended for most use cases (portable, smaller, no downtime)
2. **Volume backup** requires stopping the database for consistency
3. Backups are automatically compressed (`.sql.gz` or `.tar.gz`)
4. Old backups are automatically deleted after 30 days (configurable)
5. Always test restore procedures in a non-production environment first!

## Troubleshooting

**Backup fails: "container not running"**
```bash
docker ps | grep exp.db.keycloak
docker start exp.db.keycloak
```

**Permission denied**
```bash
chmod +x *.sh
```

**Backup directory doesn't exist**
```bash
mkdir -p provisions/backups
```


# Exporting Data from Docker Volume to Local Directory

## Command Breakdown

```powershell
docker run --rm `
    -v "exp_postgres_keycloak:/data:ro" `
    -v "${PWD}\provisions\db-data\keycloak:/backup" `
    alpine:latest `
    sh -c "cd /data && tar czf /backup/volume_data.tar.gz . && cd /backup && tar xzf volume_data.tar.gz && rm volume_data.tar.gz"
```

## Detailed Explanation

### 1. `docker run`
- **Purpose**: Creates and runs a new container
- **Why**: We need a temporary container to access the Docker volume and copy files

### 2. `--rm`
- **Purpose**: Automatically removes the container when it exits
- **Why**: We don't need to keep this temporary container after copying

### 3. `-v "exp_postgres_keycloak:/data:ro"`
- **Purpose**: Mounts a Docker volume into the container
- **Breakdown**:
  - `exp_postgres_keycloak` = Source Docker volume name
  - `:/data` = Mount point inside the container (where volume appears)
  - `:ro` = Read-only mode (we only read from the volume, don't modify it)
- **Result**: The volume's contents are accessible at `/data` inside the container

### 4. `-v "${PWD}\provisions\db-data\keycloak:/backup"`
- **Purpose**: Mounts your local directory into the container
- **Breakdown**:
  - `${PWD}` = PowerShell variable for current working directory
  - `\provisions\db-data\keycloak` = Your local directory path
  - `:/backup` = Mount point inside the container
- **Result**: Your local directory is accessible at `/backup` inside the container
- **Note**: The container can write to this directory

### 5. `alpine:latest`
- **Purpose**: The Docker image to use for the container
- **Why Alpine**: Small, lightweight Linux distribution with `tar` command included
- **Alternative**: Could use `ubuntu`, `debian`, or any Linux image with `tar`

### 6. `sh -c "..."` 
- **Purpose**: Runs a shell command inside the container
- **Why**: We need to execute multiple commands in sequence

### 7. The Shell Commands (inside `sh -c`)

#### Command Chain: `cd /data && tar czf /backup/volume_data.tar.gz . && cd /backup && tar xzf volume_data.tar.gz && rm volume_data.tar.gz`

**Step-by-step:**

1. **`cd /data`**
   - Changes directory to `/data` (where the volume is mounted)
   - This is where the PostgreSQL data files are located

2. **`&&`**
   - Logical AND operator
   - Only runs next command if previous command succeeded

3. **`tar czf /backup/volume_data.tar.gz .`**
   - **`tar`** = Archive utility
   - **`c`** = Create archive
   - **`z`** = Compress with gzip
   - **`f`** = Specify filename
   - **`/backup/volume_data.tar.gz`** = Output file path (in your local directory)
   - **`.`** = Current directory (all files in `/data`)
   - **Result**: Creates a compressed archive of all volume data

4. **`cd /backup`**
   - Changes to the backup directory (your local directory)

5. **`tar xzf volume_data.tar.gz`**
   - **`tar`** = Archive utility
   - **`x`** = Extract archive
   - **`z`** = Decompress gzip
   - **`f`** = Specify filename
   - **`volume_data.tar.gz`** = The archive we just created
   - **Result**: Extracts all files to `/backup` (your local directory)

6. **`rm volume_data.tar.gz`**
   - **`rm`** = Remove file
   - **`volume_data.tar.gz`** = The temporary archive
   - **Result**: Cleans up the temporary archive file

## Visual Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Docker Volume: exp_postgres_keycloak                        │
│  Contains: PostgreSQL data files                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ Mounted as /data (read-only)
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  Temporary Alpine Container                                  │
│                                                              │
│  /data  ────► [Volume contents]                            │
│  /backup ────► [Your local directory]                      │
│                                                              │
│  Process:                                                    │
│  1. cd /data                                                │
│  2. tar czf /backup/volume_data.tar.gz .  (compress)       │
│  3. cd /backup                                               │
│  4. tar xzf volume_data.tar.gz              (extract)       │
│  5. rm volume_data.tar.gz                  (cleanup)       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ Mounted as /backup (writable)
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  Local Directory: provisions/db-data/keycloak               │
│  Contains: Extracted PostgreSQL data files                  │
└─────────────────────────────────────────────────────────────┘
```

## Why This Approach?

1. **Volume Access**: Docker volumes can't be directly accessed from the host
2. **Temporary Container**: We use a container as a "bridge" to access the volume
3. **Two Mounts**: 
   - Volume mount (read-only) = source
   - Directory mount (writable) = destination
4. **Tar Method**: 
   - Preserves file permissions and structure
   - Handles large directories efficiently
   - Compresses during transfer (saves space temporarily)

## Alternative Methods

### Method 1: Direct Copy (if container is running)
```powershell
docker cp exp.db.keycloak:/var/lib/postgresql/data ./provisions/db-data/keycloak
```
**Limitation**: Requires the PostgreSQL container to be running

### Method 2: Using docker volume inspect + bind mount
More complex, requires finding volume location on host

### Method 3: Using the script we created
```powershell
.\provisions\backups\copy-volume-to-local.ps1
```
**Advantage**: Includes error handling and user prompts

## Summary

The command creates a temporary Alpine Linux container that:
1. **Reads** from the Docker volume (mounted at `/data`)
2. **Writes** to your local directory (mounted at `/backup`)
3. Uses `tar` to efficiently copy all files while preserving structure
4. Automatically cleans up when done (`--rm` flag)

This is the standard Docker pattern for copying data between volumes and host directories.

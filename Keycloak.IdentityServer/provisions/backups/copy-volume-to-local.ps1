# PowerShell script to copy data from Docker volume to local directory
# Usage: .\copy-volume-to-local.ps1

param(
    [string]$VolumeName = "exp_postgres_keycloak",
    [string]$LocalPath = "..\db-data\keycloak",
    [switch]$Force
)

# Configuration
$ErrorActionPreference = "Stop"
$VolumeName = $VolumeName
$LocalPath = Join-Path $PSScriptRoot $LocalPath
$ContainerName = "exp.db.keycloak"

# Colors for output
function Write-Info {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Error "Docker is not running or not accessible!"
    exit 1
}

# Check if volume exists
$volumeExists = docker volume ls --format "{{.Name}}" | Select-String -Pattern "^${VolumeName}$"
if (-not $volumeExists) {
    Write-Error "Volume ${VolumeName} does not exist!"
    exit 1
}

# Check if container is running
$containerRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "^${ContainerName}$"
if ($containerRunning) {
    Write-Warning "Container ${ContainerName} is running. For consistent copy, consider stopping it first."
    if (-not $Force) {
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Info "Copy cancelled."
            exit 0
        }
    }
}

# Create local directory if it doesn't exist
if (-not (Test-Path $LocalPath)) {
    Write-Info "Creating local directory: $LocalPath"
    New-Item -ItemType Directory -Path $LocalPath -Force | Out-Null
} else {
    if (-not $Force) {
        Write-Warning "Local directory already exists: $LocalPath"
        $response = Read-Host "This will overwrite existing data. Continue? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Info "Copy cancelled."
            exit 0
        }
    }
    # Clear existing directory
    Write-Info "Clearing existing directory..."
    Remove-Item -Path "$LocalPath\*" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Info "Starting copy from volume ${VolumeName} to ${LocalPath}..."

# Create a temporary container to copy data
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempContainer = "copy-${VolumeName}-${timestamp}"

try {
    # Use a temporary container to copy files
    Write-Info "Creating temporary container to access volume..."
    
    # Create a temporary container that mounts both the volume and local directory
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $tempContainer = "copy-${VolumeName}-${timestamp}"
    
    # Convert Windows path to WSL/Linux format for Docker
    $wslPath = $LocalPath -replace '\\', '/' -replace '^([A-Z]):', '/mnt/$1' -replace '([A-Z])', {$_.Value.ToLower()}
    
    # Use docker cp approach: create temp container, copy, then extract
    Write-Info "Extracting data from volume..."
    
    # Method: Create tar in container, stream to local, extract
    docker run --rm `
        -v "${VolumeName}:/data:ro" `
        -v "${LocalPath}:/backup" `
        alpine:latest `
        sh -c "cd /data && tar czf /backup/volume_data.tar.gz . && cd /backup && tar xzf volume_data.tar.gz && rm volume_data.tar.gz"
    
    if ($LASTEXITCODE -eq 0) {
        $itemCount = (Get-ChildItem -Path $LocalPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Info "Copy completed successfully!"
        Write-Info "Copied to: $LocalPath"
        Write-Info "Files copied: $itemCount"
        Write-Info ""
        Write-Info "Note: On Windows, you may need to adjust file permissions if you plan to use this as a bind mount."
        exit 0
    } else {
        Write-Error "Copy failed with exit code: $LASTEXITCODE"
        exit 1
    }
} catch {
    Write-Error "Copy failed: $_"
    exit 1
}


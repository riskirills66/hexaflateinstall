# PowerShell script to install by cloning repository and running docker compose

$ErrorActionPreference = "Stop"

$REPO_URL = "https://github.com/riskirills66/hexflateinstall.git"
$TEMP_DIR = [System.IO.Path]::GetTempPath()
$REPO_NAME = "hexflateinstall"
$REPO_PATH = Join-Path $TEMP_DIR $REPO_NAME

try {
    Write-Host "Cloning repository to temporary directory..."
    
    # Remove existing directory if it exists
    if (Test-Path $REPO_PATH) {
        Write-Host "Removing existing directory..."
        Remove-Item $REPO_PATH -Recurse -Force
    }
    
    git clone $REPO_URL $REPO_PATH

    if (-not (Test-Path $REPO_PATH)) {
        Write-Error "Failed to clone repository"
        exit 1
    }

    Write-Host "Changing to repository directory..."
    Set-Location $REPO_PATH

    Write-Host "Running docker compose..."
    docker compose up -d

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start docker compose"
        exit 1
    }

    Write-Host "Cleaning up repository directory..."
    Set-Location $env:TEMP
    Remove-Item $REPO_PATH -Recurse -Force

    Write-Host "Installation complete!"

} catch {
    Write-Error "An error occurred: $_"
    exit 1
}


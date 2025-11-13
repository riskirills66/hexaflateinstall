# PowerShell script to update docker-compose image from remote URL

$ErrorActionPreference = "Stop"

$COMPOSE_URL = "https://raw.githubusercontent.com/riskirills66/hexflateinstall/refs/heads/main/docker-compose.yml"
$LOCAL_COMPOSE = "docker-compose.yml"
$TEMP_COMPOSE = [System.IO.Path]::GetTempFileName()

try {
    Write-Host "Downloading docker-compose.yml from GitHub..."
    Invoke-WebRequest -Uri $COMPOSE_URL -OutFile $TEMP_COMPOSE -UseBasicParsing

    if (-not (Test-Path $TEMP_COMPOSE) -or (Get-Item $TEMP_COMPOSE).Length -eq 0) {
        Write-Error "Failed to download docker-compose.yml"
        exit 1
    }

    Write-Host "Extracting image name from remote docker-compose.yml..."
    $remoteContent = Get-Content $TEMP_COMPOSE -Raw
    
    # Extract image name using regex
    if ($remoteContent -match '(?m)^\s+image:\s*(.+)$') {
        $NEW_IMAGE = $matches[1].Trim() -replace '^["'']|["'']$', ''
    } else {
        # Alternative: look for hexcate-backend service and its image
        $lines = Get-Content $TEMP_COMPOSE
        $inService = $false
        foreach ($line in $lines) {
            if ($line -match '^\s*hexcate-backend:') {
                $inService = $true
                continue
            }
            if ($inService -and $line -match '^\s+image:\s*(.+)$') {
                $NEW_IMAGE = $matches[1].Trim() -replace '^["'']|["'']$', ''
                break
            }
            if ($inService -and $line -match '^\s+\w+:') {
                # Another service or top-level key, stop looking
                break
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($NEW_IMAGE)) {
        Write-Error "Could not extract image name from remote docker-compose.yml"
        exit 1
    }

    Write-Host "Found image: $NEW_IMAGE"

    # Check if local docker-compose.yml exists
    if (-not (Test-Path $LOCAL_COMPOSE)) {
        Write-Error "Local docker-compose.yml not found"
        exit 1
    }

    # Get current image
    $localContent = Get-Content $LOCAL_COMPOSE
    $inService = $false
    $CURRENT_IMAGE = $null
    foreach ($line in $localContent) {
        if ($line -match '^\s*hexcate-backend:') {
            $inService = $true
            continue
        }
        if ($inService -and $line -match '^\s+image:\s*(.+)$') {
            $CURRENT_IMAGE = $matches[1].Trim() -replace '^["'']|["'']$', ''
            break
        }
        if ($inService -and $line -match '^\s+\w+:') {
            break
        }
    }

    if ($CURRENT_IMAGE -eq $NEW_IMAGE) {
        Write-Host "Image is already up to date: $NEW_IMAGE"
        exit 0
    }

    Write-Host "Updating image from $CURRENT_IMAGE to $NEW_IMAGE"

    # Update the image in local docker-compose.yml
    $updatedContent = $localContent | ForEach-Object {
        if ($_ -match '^(\s+)image:\s*.+$') {
            $indent = $matches[1]
            "$indentimage: $NEW_IMAGE"
        } else {
            $_
        }
    }

    $updatedContent | Set-Content $LOCAL_COMPOSE -NoNewline

    Write-Host "Updated local docker-compose.yml"

    # Pull the new image
    Write-Host "Pulling new image..."
    docker compose pull hexcate-backend

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to pull image"
        exit 1
    }

    Write-Host "Image update complete!"
    Write-Host "To restart the service, run: docker compose up -d hexcate-backend"

} catch {
    Write-Error "An error occurred: $_"
    exit 1
} finally {
    # Cleanup
    if (Test-Path $TEMP_COMPOSE) {
        Remove-Item $TEMP_COMPOSE -Force
    }
}


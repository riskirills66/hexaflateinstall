#!/bin/bash

set -e

COMPOSE_URL="https://raw.githubusercontent.com/riskirills66/hexflateinstall/refs/heads/main/docker-compose.yml"
LOCAL_COMPOSE="docker-compose.yml"
TEMP_COMPOSE=$(mktemp)

echo "Downloading docker-compose.yml from GitHub..."
curl -s -o "$TEMP_COMPOSE" "$COMPOSE_URL"

if [ ! -s "$TEMP_COMPOSE" ]; then
    echo "Error: Failed to download docker-compose.yml" >&2
    rm -f "$TEMP_COMPOSE"
    exit 1
fi

echo "Extracting image name from remote docker-compose.yml..."
# Extract the image name from the remote file
NEW_IMAGE=$(grep -A 1 "hexcate-backend:" "$TEMP_COMPOSE" | grep "image:" | sed -E 's/^[[:space:]]*image:[[:space:]]*//' | tr -d '"' | tr -d "'")

if [ -z "$NEW_IMAGE" ]; then
    echo "Error: Could not extract image name from remote docker-compose.yml" >&2
    rm -f "$TEMP_COMPOSE"
    exit 1
fi

echo "Found image: $NEW_IMAGE"

# Check if local docker-compose.yml exists
if [ ! -f "$LOCAL_COMPOSE" ]; then
    echo "Error: Local docker-compose.yml not found" >&2
    rm -f "$TEMP_COMPOSE"
    exit 1
fi

# Get current image
CURRENT_IMAGE=$(grep -A 1 "hexcate-backend:" "$LOCAL_COMPOSE" | grep "image:" | sed -E 's/^[[:space:]]*image:[[:space:]]*//' | tr -d '"' | tr -d "'")

if [ "$CURRENT_IMAGE" = "$NEW_IMAGE" ]; then
    echo "Image is already up to date: $NEW_IMAGE"
    rm -f "$TEMP_COMPOSE"
    exit 0
fi

echo "Updating image from $CURRENT_IMAGE to $NEW_IMAGE"

# Update the image in local docker-compose.yml
# Use sed to replace the image line while preserving indentation
sed -i.bak -E "s|^([[:space:]]*image:[[:space:]]*).*|\1$NEW_IMAGE|" "$LOCAL_COMPOSE"

# Remove backup file
rm -f "${LOCAL_COMPOSE}.bak"

echo "Updated local docker-compose.yml"

# Pull the new image
echo "Pulling new image..."
docker compose pull hexcate-backend

echo "Image update complete!"
echo "To restart the service, run: docker compose up -d hexcate-backend"

# Cleanup
rm -f "$TEMP_COMPOSE"


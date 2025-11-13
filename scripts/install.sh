#!/bin/bash

set -e

REPO_URL="https://github.com/riskirills66/hexflateinstall.git"
TEMP_DIR=$(mktemp -d)
REPO_NAME="hexflateinstall"

echo "Cloning repository to temporary directory..."
git clone "$REPO_URL" "$TEMP_DIR/$REPO_NAME"

if [ ! -d "$TEMP_DIR/$REPO_NAME" ]; then
    echo "Error: Failed to clone repository" >&2
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Changing to repository directory..."
cd "$TEMP_DIR/$REPO_NAME"

echo "Running docker compose..."
docker compose up -d

echo "Cleaning up repository directory..."
cd /
rm -rf "$TEMP_DIR"

echo "Installation complete!"


#!/bin/bash
# Quick installer for Universal Dev Container
set -euo pipefail

echo "Installing Universal Dev Container..."

# Check if .devcontainer already exists
if [[ -d ".devcontainer" ]]; then
    echo "Error: .devcontainer directory already exists!"
    read -p "Backup and continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv .devcontainer .devcontainer.backup.$(date +%s)
    else
        exit 1
    fi
fi

# Download latest release (update YOUR_USERNAME to your GitHub username)
REPO="${GITHUB_USER:-YOUR_USERNAME}/universal-devcontainer"
LATEST_URL="https://api.github.com/repos/$REPO/releases/latest"
DOWNLOAD_URL=$(curl -s $LATEST_URL | grep "tarball_url" | cut -d '"' -f 4)

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "No releases found, using main branch..."
    DOWNLOAD_URL="https://github.com/$REPO/archive/main.tar.gz"
fi

# Download and extract
echo "Downloading..."
curl -L "$DOWNLOAD_URL" -o devcontainer.tar.gz
tar xzf devcontainer.tar.gz --strip=1
rm devcontainer.tar.gz

# Run setup wizard
if [[ -x ".devcontainer/scripts/setup-wizard.sh" ]]; then
    echo ""
    echo "Running setup wizard..."
    ./.devcontainer/scripts/setup-wizard.sh
fi

echo ""
echo "✓ Universal Dev Container installed successfully!"
echo "  Open this folder in VS Code and reopen in container"
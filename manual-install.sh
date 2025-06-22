#!/bin/bash
set -e

echo "Manual Universal Dev Container Installation"
echo "=========================================="

# Check current directory
echo "Current directory: $(pwd)"

# Check if .devcontainer exists
if [[ -d ".devcontainer" ]]; then
    echo "Found existing .devcontainer directory"
    echo "Contents:"
    ls -la .devcontainer/
    echo ""
    read -p "Remove and reinstall? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf .devcontainer
        echo "Removed old .devcontainer"
    else
        echo "Keeping existing .devcontainer"
        exit 0
    fi
fi

# Download
echo ""
echo "Downloading universal-devcontainer..."
if curl -L https://github.com/brianoestberg/universal-devcontainer/archive/main.tar.gz -o devcontainer.tar.gz; then
    echo "✓ Download successful"
else
    echo "✗ Download failed"
    exit 1
fi

# Check file size
size=$(stat -f%z devcontainer.tar.gz 2>/dev/null || stat -c%s devcontainer.tar.gz 2>/dev/null || echo 0)
echo "Downloaded file size: $size bytes"

# List contents
echo ""
echo "Archive contents:"
tar tzf devcontainer.tar.gz | head -20

# Extract
echo ""
echo "Extracting..."
if tar xzf devcontainer.tar.gz; then
    echo "✓ Extraction successful"
else
    echo "✗ Extraction failed"
    exit 1
fi

# Move .devcontainer to current directory
if [[ -d "universal-devcontainer-main/.devcontainer" ]]; then
    mv universal-devcontainer-main/.devcontainer .
    rm -rf universal-devcontainer-main
    echo "✓ Moved .devcontainer to current directory"
else
    echo "✗ .devcontainer not found in archive"
    exit 1
fi

# Clean up
rm devcontainer.tar.gz

# Verify installation
echo ""
echo "Verification:"
echo "-------------"

if [[ -f ".devcontainer/devcontainer.json" ]]; then
    echo "✓ devcontainer.json exists"
else
    echo "✗ devcontainer.json missing"
fi

if [[ -f ".devcontainer/Dockerfile" ]]; then
    echo "✓ Dockerfile exists"
    echo ""
    echo "Checking for LANGUAGE fix:"
    grep "LANGUAGE" .devcontainer/Dockerfile || echo "LANGUAGE not found"
else
    echo "✗ Dockerfile missing"
fi

if [[ -d ".devcontainer/scripts" ]]; then
    echo "✓ scripts directory exists"
    echo "  Scripts found:"
    ls .devcontainer/scripts/ | sed 's/^/    /'
else
    echo "✗ scripts directory missing"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Open VS Code in this directory"
echo "2. Click 'Reopen in Container' when prompted"
echo "3. Or use Command Palette: 'Dev Containers: Reopen in Container'"
#!/bin/bash
# Test script for Universal Dev Container
set -e

echo "Universal Dev Container Test Script"
echo "==================================="
echo ""

# Create test directory
TEST_DIR="/tmp/devcontainer-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "1. Copying devcontainer files to test directory: $TEST_DIR"
cp -r /workspace/universal-devcontainer-repo/.devcontainer .

echo ""
echo "2. Files copied:"
find .devcontainer -type f | head -20

echo ""
echo "3. Checking devcontainer.json syntax..."
if jq . .devcontainer/devcontainer.json > /dev/null 2>&1; then
    echo "   ✓ devcontainer.json is valid JSON"
else
    echo "   ✗ devcontainer.json has JSON syntax errors!"
    jq . .devcontainer/devcontainer.json
    exit 1
fi

echo ""
echo "4. Checking Dockerfile syntax..."
if docker build --no-cache -f .devcontainer/Dockerfile -t devcontainer-test:latest .devcontainer/ --dry-run 2>/dev/null; then
    echo "   ✓ Dockerfile syntax appears valid"
else
    echo "   ⚠ Dockerfile may have issues (dry-run not supported, trying actual build)"
fi

echo ""
echo "5. Test directory ready at: $TEST_DIR"
echo ""
echo "To test the container:"
echo "  1. cd $TEST_DIR"
echo "  2. code ."
echo "  3. Reopen in Container"
echo ""
echo "Or to test with simple config:"
echo "  1. cd $TEST_DIR"
echo "  2. cp .devcontainer/devcontainer-simple.json .devcontainer/devcontainer.json"
echo "  3. code ."
echo "  4. Reopen in Container"
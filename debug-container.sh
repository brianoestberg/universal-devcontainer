#!/bin/bash
# Debug script for container issues

echo "Container Debug Information"
echo "=========================="
echo ""

# Check Docker
echo "Docker version:"
docker --version
echo ""

# Build the container manually to see full error
echo "Building container manually..."
cd /home/brian/code/test-container/.devcontainer

# Try building with plain docker first
echo "Attempting docker build..."
docker build -t test-universal:latest \
  --build-arg TIMEZONE=UTC \
  --build-arg LOCALE=en_US.UTF-8 \
  --build-arg USERNAME=developer \
  -f Dockerfile .

if [ $? -eq 0 ]; then
    echo "✓ Docker build successful!"
    echo ""
    echo "Testing container run..."
    docker run --rm test-universal:latest /bin/bash -c "echo 'Container runs successfully!'"
else
    echo "✗ Docker build failed"
    echo ""
    echo "Trying with simpler Dockerfile..."
fi

echo ""
echo "To use minimal configuration:"
echo "cd /home/brian/code/test-container"
echo "cp .devcontainer/devcontainer-minimal.json .devcontainer/devcontainer.json"
echo "Then try 'Reopen in Container' in VS Code"
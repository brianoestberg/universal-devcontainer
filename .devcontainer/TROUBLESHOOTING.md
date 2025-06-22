# Troubleshooting Guide

## Common Issues and Solutions

### 1. Container Build Fails

**Error**: "Command failed: devContainersSpecCLI.js up"

**Solutions**:
- Check Docker is running: `docker ps`
- Ensure BuildKit is enabled: `export DOCKER_BUILDKIT=1`
- Try the simple configuration first:
  ```bash
  cp .devcontainer/devcontainer-simple.json .devcontainer/devcontainer.json
  ```
- Check Dockerfile syntax:
  ```bash
  docker build -f .devcontainer/Dockerfile .devcontainer/
  ```

### 2. Scripts Not Found

**Error**: "No such file or directory" for scripts

**Solutions**:
- Scripts are installed in `/usr/local/bin/devcontainer-scripts/`
- Use the convenience commands: `dev-update`, `dev-scan`, `dev-setup`
- Check scripts were copied during build:
  ```bash
  docker run --rm devcontainer-image ls -la /usr/local/bin/devcontainer-scripts/
  ```

### 3. Permission Denied

**Error**: "Permission denied" when running scripts

**Solutions**:
- Scripts should be executable in the container
- Run with proper user: ensure you're the `developer` user
- Check sudo permissions: `sudo -l`

### 4. Extensions Not Installing

**Error**: VS Code extensions not found

**Solutions**:
- Run manually: `/usr/local/bin/devcontainer-scripts/install-extensions.sh`
- Check VS Code server directory exists: `ls -la ~/.vscode-server/`
- Verify network connectivity to marketplace.visualstudio.com

### 5. Volume Mount Issues

**Error**: "Mount failed" or "Invalid mount config"

**Solutions**:
- Simplify mounts in devcontainer.json:
  ```json
  "mounts": [
    "source=devcontainer-history,target=/commandhistory,type=volume"
  ]
  ```
- Check Docker volume permissions
- Use bind mounts for testing

### 6. Locale/Encoding Issues

**Error**: Character encoding problems

**Solutions**:
- Container sets UTF-8 by default
- Check locale: `locale`
- Regenerate if needed: `sudo locale-gen en_US.UTF-8`

## Debug Commands

Run these inside the container:

```bash
# Check environment
env | grep -E "(DEVCONTAINER|LANG|USER)"

# Check user
whoami
id

# Check scripts location
ls -la /usr/local/bin/devcontainer-scripts/
ls -la /usr/local/bin/dev-*

# Check VS Code directories
ls -la ~/.vscode-server/

# Test script execution
/usr/local/bin/devcontainer-scripts/install-extensions.sh

# Check logs
cat /tmp/update.log
journalctl -xe
```

## Minimal Test Configuration

Create `.devcontainer/devcontainer.json`:

```json
{
  "name": "Test",
  "image": "ubuntu:22.04",
  "remoteUser": "root"
}
```

If this works, gradually add features from the universal container.

## Getting Help

1. Check the logs in VS Code Output panel
2. Run the test script: `./test-container.sh`
3. Use simple configuration first
4. Report issues with full error messages
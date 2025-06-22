# Windows Setup Guide for Universal Dev Container

This guide provides step-by-step instructions for setting up the Universal Dev Container on Windows.

## 🚀 Quick Start (TL;DR)

1. **Run PowerShell as Administrator** and execute:
   ```powershell
   # One-time setup
   wsl --install
   # Restart when prompted
   ```

2. **Install required software**:
   - [Docker Desktop](https://www.docker.com/products/docker-desktop/) (use WSL2 backend)
   - [VS Code](https://code.visualstudio.com/) + Dev Containers extension

3. **In your project folder**:
   ```powershell
   # Download and run our Windows installer
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/brianoestberg/universal-devcontainer/main/install-windows.ps1" -OutFile install-windows.ps1
   .\install-windows.ps1
   
   # Open in VS Code
   code .
   ```

4. **Click "Reopen in Container"** when VS Code prompts you.

That's it! For detailed instructions, continue reading below.

## Prerequisites

### 1. System Requirements
- Windows 10 version 2004 or higher (Build 19041 or higher)
- Windows 11 (any version)
- At least 8GB RAM (16GB recommended)
- 20GB free disk space

### 2. Enable WSL2 (Windows Subsystem for Linux)

1. **Open PowerShell as Administrator**:
   - Right-click Start button → "Windows PowerShell (Admin)"

2. **Enable WSL**:
   ```powershell
   wsl --install
   ```
   This command will:
   - Enable required Windows features
   - Install WSL2
   - Install Ubuntu as default Linux distribution
   - Restart your computer (required)

3. **After restart, Ubuntu will open automatically**:
   - Create a username and password when prompted
   - Remember these credentials!

4. **Verify WSL2 is default**:
   ```powershell
   wsl --set-default-version 2
   ```

### 3. Install Docker Desktop

1. **Download Docker Desktop**:
   - Go to https://www.docker.com/products/docker-desktop/
   - Click "Download for Windows"

2. **Install Docker Desktop**:
   - Run the installer
   - Keep "Use WSL 2 instead of Hyper-V" checked
   - Click "Ok" to install

3. **Start Docker Desktop**:
   - Docker Desktop will start automatically
   - Wait for "Docker Desktop is running" in system tray

4. **Configure Docker Desktop**:
   - Right-click Docker icon in system tray → Settings
   - General: Ensure "Use the WSL 2 based engine" is checked
   - Resources → WSL Integration: Enable integration with your Ubuntu distro

### 4. Install Visual Studio Code

1. **Download VS Code**:
   - Go to https://code.visualstudio.com/
   - Click "Download for Windows"

2. **Install VS Code**:
   - Run the installer
   - Check "Add to PATH" option
   - Complete installation

3. **Install Required Extensions**:
   - Open VS Code
   - Press `Ctrl+Shift+X` to open Extensions
   - Search and install:
     - "Dev Containers" by Microsoft
     - "WSL" by Microsoft

## Setting Up Your First Project

### Option 1: New Project

1. **Create a new folder**:
   ```powershell
   mkdir C:\Projects\my-new-app
   cd C:\Projects\my-new-app
   ```

2. **Download the Universal Dev Container**:
   ```powershell
   # In PowerShell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/brianoestberg/universal-devcontainer/main/install.sh" -OutFile install.sh
   
   # Run in WSL
   wsl bash install.sh
   ```

3. **Open in VS Code**:
   ```powershell
   code .
   ```

4. **Reopen in Container**:
   - VS Code will detect the `.devcontainer` folder
   - Click "Reopen in Container" in the notification
   - Or press `F1` → type "Reopen in Container"

### Option 2: Existing Project

1. **Open your project in VS Code**:
   ```powershell
   cd C:\Projects\your-existing-project
   code .
   ```

2. **Open Terminal in VS Code**:
   - Press `` Ctrl+` `` to open terminal
   - Click the dropdown arrow → "Ubuntu (WSL)"

3. **Install Universal Dev Container**:
   ```bash
   curl -sSL https://raw.githubusercontent.com/brianoestberg/universal-devcontainer/main/install.sh | bash
   ```

4. **Run Setup Wizard**:
   ```bash
   ./.devcontainer/scripts/setup-wizard.sh
   ```

5. **Reopen in Container**:
   - Press `F1` → type "Reopen in Container"
   - Wait for container to build (first time takes 2-3 minutes)

## First Time Setup

When the container starts for the first time:

1. **Terminal Opens Automatically**:
   - You'll be in `/workspace` directory
   - Shell is Zsh with nice prompt

2. **Run Initial Setup** (if not done):
   ```bash
   dev-setup
   ```
   This will:
   - Configure Git with your name/email
   - Set up SSH keys (optional)
   - Install project dependencies

3. **Check Everything Works**:
   ```bash
   # Check Git
   git --version
   
   # Check installed extensions
   code --list-extensions
   
   # Run security scan
   dev-scan
   ```

## Common Windows Issues & Solutions

### Issue: "Docker Desktop - WSL Integration Error"
**Solution**: 
1. Open Docker Desktop Settings
2. Go to Resources → WSL Integration
3. Toggle off and on your Ubuntu distribution
4. Restart Docker Desktop

### Issue: "Cannot connect to Docker daemon"
**Solution**:
1. Ensure Docker Desktop is running (check system tray)
2. In PowerShell: `wsl --shutdown`
3. Restart Docker Desktop
4. Try again

### Issue: "Permission denied" errors
**Solution**:
1. In WSL terminal: `sudo chown -R $(whoami) .`
2. Or rebuild container: `F1` → "Rebuild Container"

### Issue: Slow file operations
**Solution**:
1. Clone projects inside WSL filesystem:
   ```bash
   cd ~
   git clone https://github.com/your/repo.git
   cd repo
   code .
   ```
2. Avoid using `/mnt/c/` paths when possible

### Issue: Line ending problems (CRLF vs LF)
**Solution**:
1. Configure Git globally:
   ```bash
   git config --global core.autocrlf input
   ```
2. In VS Code: Set default line ending to LF
   - `File → Preferences → Settings`
   - Search "eol"
   - Set to `\n` (LF)

## Performance Tips

1. **Use WSL2 filesystem**:
   - Store projects in `\\wsl$\Ubuntu\home\yourusername\`
   - Not in `C:\` for better performance

2. **Allocate Resources**:
   - Docker Desktop → Settings → Resources
   - Increase CPU and Memory limits

3. **Windows Defender Exclusions**:
   - Add Docker and WSL directories to exclusions
   - Settings → Update & Security → Windows Security → Virus & threat protection → Manage settings → Add exclusions

## VS Code Tips

1. **Open WSL projects quickly**:
   ```powershell
   # From Windows
   code \\wsl$\Ubuntu\home\yourusername\project
   
   # Or from WSL
   cd ~/project && code .
   ```

2. **Terminal Shortcuts**:
   - `` Ctrl+` ``: Open/close terminal
   - `Ctrl+Shift+5`: Split terminal
   - `Ctrl+PgUp/PgDn`: Switch terminals

3. **Container Commands**:
   - `F1` → "Dev Containers: Rebuild Container"
   - `F1` → "Dev Containers: Reopen Locally"
   - `F1` → "Dev Containers: Show Container Log"

## Next Steps

1. **Customize Your Environment**:
   - Edit `.devcontainer/config.yaml`
   - Add your dotfiles repository
   - Configure optional extensions

2. **Learn the Shortcuts**:
   - `dev-update`: Update tools
   - `dev-scan`: Security check
   - `dev-extensions`: Manage extensions

3. **Share With Your Team**:
   - Commit `.devcontainer` folder to your repo
   - Team members just need to clone and "Reopen in Container"

## Getting Help

- **Container Logs**: `F1` → "Dev Containers: Show Container Log"
- **Rebuild**: `F1` → "Dev Containers: Rebuild Container"
- **Issues**: https://github.com/brianoestberg/universal-devcontainer/issues

## Quick Reference Card

```powershell
# First time setup (PowerShell)
wsl --install
# Restart computer
# Install Docker Desktop
# Install VS Code + Extensions

# New project (PowerShell)
mkdir C:\Projects\my-app
cd C:\Projects\my-app
wsl bash -c "curl -sSL https://raw.githubusercontent.com/brianoestberg/universal-devcontainer/main/install.sh | bash"
code .
# Click "Reopen in Container"

# Daily workflow
code C:\Projects\my-app  # Open VS Code
# F1 → "Reopen in Container"
# Start coding!
```

---

Happy coding! 🚀
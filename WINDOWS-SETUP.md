# Windows Setup Guide for Universal Dev Container

This guide provides step-by-step instructions for setting up the Universal Dev Container on Windows.

## 🚀 Quick Start (TL;DR)

### Prerequisites (One-time setup)
1. **Install WSL2** - Run PowerShell as Administrator:
   ```powershell
   wsl --install
   # Restart computer when prompted
   ```

2. **Install required software**:
   - [Docker Desktop](https://www.docker.com/products/docker-desktop/) (use WSL2 backend)
   - [VS Code](https://code.visualstudio.com/) + Dev Containers extension

### Create Your Project (Recommended: WSL filesystem)
3. **Open WSL** from PowerShell:
   ```powershell
   wsl
   ```
   
4. **In WSL/Linux** (you'll see your prompt change), create project:
   ```bash
   # Now you're in Linux - create project in your home directory
   cd ~
   mkdir my-project
   cd my-project
   
   # Install dev container
   curl -sSL https://raw.githubusercontent.com/brianoestberg/universal-devcontainer/main/install.sh | bash
   
   # Open in VS Code
   code .
   ```

5. **In VS Code**: Click "Reopen in Container" when prompted.

That's it! For detailed instructions, continue reading below.

## Understanding Windows vs WSL

### Key Concepts
- **PowerShell**: Windows command line (shows `PS C:\>`)
- **WSL**: Linux running inside Windows (shows `username@computer:~$`)
- **Where to run commands**: 
  - PowerShell commands start with `PS C:\>`
  - WSL/Linux commands start with `$`
- **File locations**:
  - Windows: `C:\Projects\my-app`
  - WSL: `/home/username/my-app` (or `~/my-app`)
  - Access WSL files from Windows: `\\wsl$\Ubuntu\home\username\my-app`
  - Access Windows files from WSL: `/mnt/c/Projects/my-app`

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

### Option 1: WSL Filesystem (Recommended - Better Performance)

1. **Open PowerShell** and start WSL:
   ```powershell
   # In PowerShell - this opens WSL/Linux
   wsl
   ```
   
   Your prompt will change from `PS C:\>` to something like `username@computer:~$`

2. **Create project in Linux home directory**:
   ```bash
   # You are now in WSL/Linux - notice the $ prompt
   cd ~                    # Go to your Linux home directory
   mkdir my-new-app       # Create project folder
   cd my-new-app          # Enter the folder
   pwd                    # Shows: /home/yourusername/my-new-app
   ```

3. **Install the Universal Dev Container**:
   ```bash
   # Still in WSL/Linux
   curl -sSL https://raw.githubusercontent.com/brianoestberg/universal-devcontainer/main/install.sh | bash
   ```

4. **Open in VS Code**:
   ```bash
   # Still in WSL/Linux
   code .
   ```
   VS Code will open on Windows, connected to your WSL folder

5. **Reopen in Container**:
   - VS Code will show: "Folder contains a Dev Container configuration"
   - Click "Reopen in Container"
   - First build: 2-3 minutes

### Option 2: Windows Filesystem (Simpler but Slower)

1. **In PowerShell** (stay in Windows):
   ```powershell
   # In PowerShell - notice the PS prompt
   mkdir C:\Projects\my-new-app
   cd C:\Projects\my-new-app
   ```

2. **Run the Windows installer**:
   ```powershell
   # Download installer
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/brianoestberg/universal-devcontainer/main/install-windows.ps1" -OutFile install-windows.ps1
   
   # Run it
   .\install-windows.ps1
   ```

3. **Open in VS Code**:
   ```powershell
   # Still in PowerShell
   code .
   ```

4. **Reopen in Container** (same as Option 1)

### Option 3: Existing Project

#### For WSL Project:
1. **Open WSL and navigate to your project**:
   ```powershell
   # In PowerShell
   wsl
   ```
   ```bash
   # Now in WSL/Linux
   cd ~/your-existing-project
   code .
   ```

#### For Windows Project:
1. **Open your project**:
   ```powershell
   # In PowerShell
   cd C:\Projects\your-existing-project
   code .
   ```

2. **In VS Code Terminal** (`` Ctrl+` ``):
   - Click dropdown → "Ubuntu (WSL)" or "Git Bash"
   - You need a Linux terminal for the curl command

3. **Install Universal Dev Container**:
   ```bash
   # In the Linux terminal within VS Code
   curl -sSL https://raw.githubusercontent.com/brianoestberg/universal-devcontainer/main/install.sh | bash
   ```

4. **Reopen in Container**:
   - Press `F1` → type "Reopen in Container"
   - Or click the notification

## Understanding Where You Are

### Visual Indicators

**PowerShell (Windows)**:
```
PS C:\Users\YourName>
```

**WSL/Linux**:
```
yourname@computer:~$
```

**Inside Dev Container**:
```
developer@a1b2c3d4:/workspace$
```

### Quick Check Commands
```bash
# Where am I?
pwd                    # Shows current directory

# Windows or Linux?
uname                  # Linux shows "Linux", Windows won't recognize

# Inside container?
echo $DEVCONTAINER     # Shows "true" if in container
```

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

### First Time Setup (Run Once)
```powershell
# In PowerShell as Administrator
wsl --install
# Restart computer when prompted
```
Then install:
- [Docker Desktop](https://docker.com/products/docker-desktop/)
- [VS Code](https://code.visualstudio.com/)

### Daily Workflow - New Project (Recommended)
```powershell
# Step 1: In PowerShell
wsl                             # Opens Linux

# Step 2: In WSL/Linux (notice prompt change to $)
cd ~                           # Go to Linux home
mkdir my-project               # Create project
cd my-project                  # Enter project
curl -sSL https://raw.githubusercontent.com/brianoestberg/universal-devcontainer/main/install.sh | bash
code .                         # Opens VS Code

# Step 3: In VS Code
# Click "Reopen in Container" when prompted
```

### Daily Workflow - Existing Project
```powershell
# In PowerShell
wsl                            # Opens Linux
cd ~/my-project                # Go to your project
code .                         # Opens VS Code
# VS Code reopens in container automatically
```

---

Happy coding! 🚀
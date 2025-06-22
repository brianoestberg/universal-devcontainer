# Universal Dev Container - Windows Installer
# This script helps Windows users install the dev container

Write-Host "Universal Dev Container - Windows Installer" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Function to check if a command exists
function Test-CommandExists {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Windows version
$os = Get-WmiObject -Class Win32_OperatingSystem
$version = [System.Version]$os.Version
if ($version.Major -lt 10 -or ($version.Major -eq 10 -and $version.Build -lt 19041)) {
    Write-Host "ERROR: Windows 10 version 2004 (Build 19041) or higher required" -ForegroundColor Red
    Write-Host "Your version: Windows $($version.Major) Build $($version.Build)" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Windows version OK" -ForegroundColor Green

# Check WSL
if (Test-CommandExists "wsl") {
    $wslVersion = wsl --list --verbose 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ WSL is installed" -ForegroundColor Green
    } else {
        Write-Host "✗ WSL needs to be configured" -ForegroundColor Yellow
        $installWSL = $true
    }
} else {
    Write-Host "✗ WSL is not installed" -ForegroundColor Yellow
    $installWSL = $true
}

# Check Docker
if (Test-CommandExists "docker") {
    Write-Host "✓ Docker is installed" -ForegroundColor Green
} else {
    Write-Host "✗ Docker Desktop is not installed" -ForegroundColor Yellow
    $installDocker = $true
}

# Check VS Code
if (Test-CommandExists "code") {
    Write-Host "✓ VS Code is installed" -ForegroundColor Green
} else {
    Write-Host "✗ VS Code is not installed" -ForegroundColor Yellow
    $installVSCode = $true
}

Write-Host ""

# Install missing components
if ($installWSL) {
    Write-Host "Installing WSL2..." -ForegroundColor Yellow
    if (!$isAdmin) {
        Write-Host "ERROR: Administrator privileges required to install WSL" -ForegroundColor Red
        Write-Host "Please run this script as Administrator" -ForegroundColor Red
        exit 1
    }
    
    wsl --install
    Write-Host ""
    Write-Host "IMPORTANT: WSL installation requires a restart!" -ForegroundColor Cyan
    Write-Host "After restart:" -ForegroundColor Yellow
    Write-Host "1. Ubuntu will open automatically - create username/password" -ForegroundColor Yellow
    Write-Host "2. Run this script again to continue setup" -ForegroundColor Yellow
    Write-Host ""
    $restart = Read-Host "Restart now? (Y/n)"
    if ($restart -ne "n") {
        Restart-Computer
    }
    exit 0
}

if ($installDocker) {
    Write-Host "Docker Desktop is required" -ForegroundColor Yellow
    Write-Host "1. Download from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    Write-Host "2. Install Docker Desktop (keep WSL2 option checked)" -ForegroundColor Cyan
    Write-Host "3. Start Docker Desktop" -ForegroundColor Cyan
    Write-Host "4. Run this script again" -ForegroundColor Cyan
    Write-Host ""
    $openDocker = Read-Host "Open Docker Desktop download page? (Y/n)"
    if ($openDocker -ne "n") {
        Start-Process "https://www.docker.com/products/docker-desktop/"
    }
    exit 0
}

if ($installVSCode) {
    Write-Host "VS Code is required" -ForegroundColor Yellow
    Write-Host "1. Download from: https://code.visualstudio.com/" -ForegroundColor Cyan
    Write-Host "2. Install VS Code (keep 'Add to PATH' checked)" -ForegroundColor Cyan
    Write-Host "3. Run this script again" -ForegroundColor Cyan
    Write-Host ""
    $openVSCode = Read-Host "Open VS Code download page? (Y/n)"
    if ($openVSCode -ne "n") {
        Start-Process "https://code.visualstudio.com/"
    }
    exit 0
}

# Check if VS Code extensions are installed
Write-Host "Checking VS Code extensions..." -ForegroundColor Yellow
$extensions = code --list-extensions 2>$null
$requiredExtensions = @("ms-vscode-remote.remote-containers", "ms-vscode-remote.remote-wsl")
$missingExtensions = @()

foreach ($ext in $requiredExtensions) {
    if ($extensions -notcontains $ext) {
        $missingExtensions += $ext
    }
}

if ($missingExtensions.Count -gt 0) {
    Write-Host "Installing required VS Code extensions..." -ForegroundColor Yellow
    foreach ($ext in $missingExtensions) {
        code --install-extension $ext
    }
    Write-Host "✓ VS Code extensions installed" -ForegroundColor Green
} else {
    Write-Host "✓ VS Code extensions OK" -ForegroundColor Green
}

Write-Host ""
Write-Host "All prerequisites installed!" -ForegroundColor Green
Write-Host ""

# Install dev container
Write-Host "Installing Universal Dev Container..." -ForegroundColor Cyan

# Create .devcontainer directory if it doesn't exist
if (!(Test-Path ".devcontainer")) {
    # Download and run install script in WSL
    Write-Host "Downloading dev container files..." -ForegroundColor Yellow
    
    $installScript = @'
#!/bin/bash
curl -sSL https://raw.githubusercontent.com/brianoestberg/universal-devcontainer/main/install.sh | bash
'@
    
    # Save script temporarily
    $installScript | Out-File -FilePath "temp-install.sh" -Encoding ASCII -NoNewline
    
    # Run in WSL
    wsl bash temp-install.sh
    
    # Clean up
    Remove-Item "temp-install.sh"
    
    Write-Host "✓ Dev container installed!" -ForegroundColor Green
} else {
    Write-Host "✓ Dev container already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Open this folder in VS Code: " -NoNewline -ForegroundColor Yellow
Write-Host "code ." -ForegroundColor White
Write-Host "2. When prompted, click " -NoNewline -ForegroundColor Yellow
Write-Host "'Reopen in Container'" -ForegroundColor White
Write-Host "3. Wait for container to build (first time: 2-3 minutes)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Happy coding! 🚀" -ForegroundColor Cyan
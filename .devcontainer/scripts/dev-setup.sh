#!/bin/bash
# Developer environment setup and productivity tools
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config/devcontainer"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/../config.yaml}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[Dev Setup]${NC} $1"
}

info() {
    echo -e "${BLUE}[Dev Setup]${NC} $1"
}

# Setup Git configuration
setup_git() {
    log "Configuring Git..."
    
    # Check if user has git config
    if [[ -z "$(git config --global user.name)" ]]; then
        read -p "Enter your Git name: " git_name
        git config --global user.name "$git_name"
    fi
    
    if [[ -z "$(git config --global user.email)" ]]; then
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    fi
    
    # Set up useful Git aliases
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.visual '!gitk'
    git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    
    info "Git configured successfully"
}

# Setup SSH keys
setup_ssh() {
    log "Setting up SSH..."
    
    if [[ ! -f ~/.ssh/id_rsa ]] && [[ ! -f ~/.ssh/id_ed25519 ]]; then
        read -p "Generate SSH key? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f ~/.ssh/id_ed25519
            eval "$(ssh-agent -s)"
            ssh-add ~/.ssh/id_ed25519
            
            info "SSH key generated. Public key:"
            cat ~/.ssh/id_ed25519.pub
            info "Add this key to your GitHub/GitLab account"
        fi
    else
        info "SSH keys already exist"
    fi
}

# Setup GPG for commit signing
setup_gpg() {
    log "Setting up GPG..."
    
    if ! command -v gpg &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y gnupg2
    fi
    
    if [[ -z "$(gpg --list-secret-keys --keyid-format LONG)" ]]; then
        read -p "Generate GPG key for commit signing? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gpg --full-generate-key
            
            # Get the key ID
            KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | tail -1 | awk '{print $2}' | cut -d'/' -f2)
            
            if [[ -n "$KEY_ID" ]]; then
                git config --global user.signingkey "$KEY_ID"
                git config --global commit.gpgsign true
                
                info "GPG key configured. Public key:"
                gpg --armor --export "$KEY_ID"
                info "Add this key to your GitHub/GitLab account"
            fi
        fi
    else
        info "GPG keys already exist"
    fi
}

# Install dotfiles
install_dotfiles() {
    log "Setting up dotfiles..."
    
    # Check if dotfiles repo is configured
    local dotfiles_repo="${DOTFILES_REPO:-}"
    
    if [[ -n "$dotfiles_repo" ]]; then
        log "Installing dotfiles from $dotfiles_repo..."
        
        local dotfiles_dir="${HOME}/.dotfiles"
        
        if [[ ! -d "$dotfiles_dir" ]]; then
            git clone "$dotfiles_repo" "$dotfiles_dir"
            
            # Run install script if exists
            if [[ -f "$dotfiles_dir/install.sh" ]]; then
                cd "$dotfiles_dir" && ./install.sh
            elif [[ -f "$dotfiles_dir/Makefile" ]]; then
                cd "$dotfiles_dir" && make install
            else
                info "No install script found in dotfiles repo"
            fi
        else
            info "Dotfiles already installed"
        fi
    else
        info "No dotfiles repository configured"
    fi
}

# Setup project-specific tools
setup_project_tools() {
    log "Setting up project-specific tools..."
    
    # Node.js project
    if [[ -f "package.json" ]]; then
        log "Detected Node.js project"
        
        # Install nvm if not present
        if ! command -v nvm &> /dev/null; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        fi
        
        # Install Node version from .nvmrc if exists
        if [[ -f ".nvmrc" ]]; then
            nvm install
            nvm use
        fi
        
        # Install dependencies
        if [[ -f "package-lock.json" ]]; then
            npm ci
        elif [[ -f "yarn.lock" ]]; then
            yarn install --frozen-lockfile
        elif [[ -f "pnpm-lock.yaml" ]]; then
            pnpm install --frozen-lockfile
        else
            npm install
        fi
    fi
    
    # Python project
    if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
        log "Detected Python project"
        
        # Create virtual environment if not exists
        if [[ ! -d "venv" ]] && [[ ! -d ".venv" ]]; then
            python3 -m venv venv
            source venv/bin/activate
        fi
        
        # Install dependencies
        if [[ -f "requirements.txt" ]]; then
            pip install -r requirements.txt
        elif [[ -f "pyproject.toml" ]]; then
            pip install -e .
        fi
    fi
    
    # Go project
    if [[ -f "go.mod" ]]; then
        log "Detected Go project"
        go mod download
    fi
    
    # Rust project
    if [[ -f "Cargo.toml" ]]; then
        log "Detected Rust project"
        
        # Install Rust if not present
        if ! command -v rustc &> /dev/null; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source $HOME/.cargo/env
        fi
        
        cargo build
    fi
}

# Create useful aliases
create_aliases() {
    log "Setting up aliases..."
    
    # Add to shell rc file
    local shell_rc="${HOME}/.zshrc"
    
    if [[ -f "$shell_rc" ]]; then
        # Development aliases
        echo "" >> "$shell_rc"
        echo "# DevContainer aliases" >> "$shell_rc"
        echo "alias ll='ls -alF'" >> "$shell_rc"
        echo "alias la='ls -A'" >> "$shell_rc"
        echo "alias l='ls -CF'" >> "$shell_rc"
        echo "alias ..='cd ..'" >> "$shell_rc"
        echo "alias ...='cd ../..'" >> "$shell_rc"
        echo "alias dev-update='${SCRIPT_DIR}/update-tools.sh'" >> "$shell_rc"
        echo "alias dev-scan='${SCRIPT_DIR}/security-scan.sh'" >> "$shell_rc"
        echo "alias dev-extensions='${SCRIPT_DIR}/install-extensions.sh'" >> "$shell_rc"
        
        # Git aliases
        echo "alias gs='git status'" >> "$shell_rc"
        echo "alias gd='git diff'" >> "$shell_rc"
        echo "alias gc='git commit'" >> "$shell_rc"
        echo "alias gp='git push'" >> "$shell_rc"
        echo "alias gl='git pull'" >> "$shell_rc"
        echo "alias glog='git log --oneline --graph'" >> "$shell_rc"
        
        # Docker aliases if Docker is available
        if command -v docker &> /dev/null; then
            echo "alias dps='docker ps'" >> "$shell_rc"
            echo "alias dpsa='docker ps -a'" >> "$shell_rc"
            echo "alias di='docker images'" >> "$shell_rc"
            echo "alias dex='docker exec -it'" >> "$shell_rc"
        fi
        
        info "Aliases configured"
    fi
}

# Setup workspace
setup_workspace() {
    log "Setting up workspace..."
    
    # Create common directories
    mkdir -p "${HOME}/.config/devcontainer"
    mkdir -p "${HOME}/.local/bin"
    mkdir -p "${HOME}/.cache"
    
    # Add local bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc"
    fi
    
    # Set up workspace permissions
    if [[ -d "/workspace" ]]; then
        sudo chown -R $(whoami):$(whoami) /workspace 2>/dev/null || true
    fi
}

# Main setup function
main() {
    log "Starting developer environment setup..."
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Run setup steps
    setup_workspace
    setup_git
    setup_ssh
    # setup_gpg  # Optional, uncomment if needed
    install_dotfiles
    create_aliases
    setup_project_tools
    
    # Install VS Code extensions
    "${SCRIPT_DIR}/install-extensions.sh"
    
    # Run initial security scan
    "${SCRIPT_DIR}/security-scan.sh" --secrets
    
    log "Developer environment setup completed!"
    info "Restart your shell or run 'source ~/.zshrc' to apply changes"
}

# Parse arguments
SKIP_INTERACTIVE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive)
            SKIP_INTERACTIVE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Run main function
main
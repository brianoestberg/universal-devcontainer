#!/bin/bash
# Automatically install project dependencies based on detected project type
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[Dependencies]${NC} $1"
}

info() {
    echo -e "${BLUE}[Dependencies]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[Dependencies]${NC} $1"
}

# Node.js/JavaScript dependencies
install_node_deps() {
    log "Installing Node.js dependencies..."
    
    # Check for Node version manager
    if [[ -f ".nvmrc" ]] && command -v nvm &> /dev/null; then
        log "Using Node version from .nvmrc"
        nvm install
        nvm use
    elif [[ -f ".node-version" ]] && command -v nodenv &> /dev/null; then
        log "Using Node version from .node-version"
        nodenv install -s
        nodenv local
    fi
    
    # Install dependencies
    if [[ -f "package-lock.json" ]]; then
        log "Found package-lock.json, using npm ci"
        npm ci
    elif [[ -f "yarn.lock" ]]; then
        log "Found yarn.lock, using yarn install"
        if ! command -v yarn &> /dev/null; then
            npm install -g yarn
        fi
        yarn install --frozen-lockfile
    elif [[ -f "pnpm-lock.yaml" ]]; then
        log "Found pnpm-lock.yaml, using pnpm install"
        if ! command -v pnpm &> /dev/null; then
            npm install -g pnpm
        fi
        pnpm install --frozen-lockfile
    else
        log "No lock file found, using npm install"
        npm install
    fi
    
    # Install global tools if specified
    if [[ -f ".devcontainer/global-packages.txt" ]]; then
        log "Installing global npm packages..."
        cat .devcontainer/global-packages.txt | xargs npm install -g
    fi
}

# Python dependencies
install_python_deps() {
    log "Installing Python dependencies..."
    
    # Create virtual environment if it doesn't exist
    if [[ ! -d "venv" ]] && [[ ! -d ".venv" ]] && [[ ! -d "env" ]]; then
        log "Creating virtual environment..."
        python3 -m venv venv
        source venv/bin/activate
    else
        # Activate existing virtual environment
        if [[ -d "venv" ]]; then
            source venv/bin/activate
        elif [[ -d ".venv" ]]; then
            source .venv/bin/activate
        elif [[ -d "env" ]]; then
            source env/bin/activate
        fi
    fi
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install dependencies
    if [[ -f "requirements.txt" ]]; then
        log "Installing from requirements.txt"
        pip install -r requirements.txt
    fi
    
    if [[ -f "requirements-dev.txt" ]]; then
        log "Installing from requirements-dev.txt"
        pip install -r requirements-dev.txt
    fi
    
    if [[ -f "setup.py" ]]; then
        log "Installing from setup.py"
        pip install -e .
    fi
    
    if [[ -f "pyproject.toml" ]]; then
        if grep -q "poetry" pyproject.toml; then
            log "Detected Poetry project"
            if ! command -v poetry &> /dev/null; then
                pip install poetry
            fi
            poetry install
        else
            log "Installing from pyproject.toml"
            pip install -e .
        fi
    fi
    
    if [[ -f "Pipfile" ]]; then
        log "Detected Pipenv project"
        if ! command -v pipenv &> /dev/null; then
            pip install pipenv
        fi
        pipenv install --dev
    fi
}

# Go dependencies
install_go_deps() {
    log "Installing Go dependencies..."
    
    if [[ -f "go.mod" ]]; then
        go mod download
        go mod tidy
    fi
    
    # Install common Go tools
    if [[ -f ".devcontainer/go-tools.txt" ]]; then
        log "Installing Go tools..."
        cat .devcontainer/go-tools.txt | xargs -I {} go install {}
    fi
}

# Rust dependencies
install_rust_deps() {
    log "Installing Rust dependencies..."
    
    # Install Rust if not present
    if ! command -v rustc &> /dev/null; then
        log "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
    fi
    
    if [[ -f "Cargo.toml" ]]; then
        cargo fetch
        cargo build --release
    fi
}

# Ruby dependencies
install_ruby_deps() {
    log "Installing Ruby dependencies..."
    
    # Check for Ruby version manager
    if [[ -f ".ruby-version" ]]; then
        if command -v rbenv &> /dev/null; then
            log "Using Ruby version from .ruby-version"
            rbenv install -s
            rbenv local
        elif command -v rvm &> /dev/null; then
            rvm install $(cat .ruby-version)
            rvm use $(cat .ruby-version)
        fi
    fi
    
    if [[ -f "Gemfile" ]]; then
        if ! command -v bundle &> /dev/null; then
            gem install bundler
        fi
        bundle install
    fi
}

# Java dependencies
install_java_deps() {
    log "Installing Java dependencies..."
    
    if [[ -f "pom.xml" ]]; then
        if command -v mvn &> /dev/null; then
            mvn dependency:resolve
        else
            warning "Maven not found, skipping Java dependencies"
        fi
    fi
    
    if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        if command -v gradle &> /dev/null; then
            gradle dependencies
        elif [[ -f "gradlew" ]]; then
            ./gradlew dependencies
        else
            warning "Gradle not found, skipping Java dependencies"
        fi
    fi
}

# PHP dependencies
install_php_deps() {
    log "Installing PHP dependencies..."
    
    if [[ -f "composer.json" ]]; then
        if ! command -v composer &> /dev/null; then
            log "Installing Composer..."
            curl -sS https://getcomposer.org/installer | php
            sudo mv composer.phar /usr/local/bin/composer
        fi
        composer install
    fi
}

# Main installation
main() {
    log "Detecting and installing project dependencies..."
    
    # Track what was installed
    local installed=()
    
    # Check each project type
    if [[ -f "package.json" ]]; then
        install_node_deps
        installed+=("Node.js")
    fi
    
    if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]] || [[ -f "Pipfile" ]]; then
        install_python_deps
        installed+=("Python")
    fi
    
    if [[ -f "go.mod" ]]; then
        install_go_deps
        installed+=("Go")
    fi
    
    if [[ -f "Cargo.toml" ]]; then
        install_rust_deps
        installed+=("Rust")
    fi
    
    if [[ -f "Gemfile" ]]; then
        install_ruby_deps
        installed+=("Ruby")
    fi
    
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        install_java_deps
        installed+=("Java")
    fi
    
    if [[ -f "composer.json" ]]; then
        install_php_deps
        installed+=("PHP")
    fi
    
    # Summary
    if [[ ${#installed[@]} -eq 0 ]]; then
        info "No project dependencies detected"
    else
        log "Successfully installed dependencies for: ${installed[*]}"
    fi
    
    # Run custom install script if exists
    if [[ -f ".devcontainer/install.sh" ]]; then
        log "Running custom install script..."
        bash .devcontainer/install.sh
    fi
}

# Run main function
main "$@"
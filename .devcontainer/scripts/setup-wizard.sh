#!/bin/bash
# Interactive setup wizard for Universal Dev Container
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVCONTAINER_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="${DEVCONTAINER_DIR}/config.yaml"
BACKUP_DIR="${DEVCONTAINER_DIR}/.backup"

# Welcome message
show_welcome() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║        Universal Dev Container Setup Wizard              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${GREEN}Welcome!${NC} This wizard will help you set up your development container."
    echo ""
}

# Detect project information
detect_project() {
    echo -e "${BLUE}${BOLD}Detecting Project Information...${NC}"
    echo ""
    
    local project_types=()
    local project_name=$(basename "$(pwd)")
    
    # Detect project types
    if [[ -f "package.json" ]]; then
        project_types+=("Node.js/JavaScript")
    fi
    if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
        project_types+=("Python")
    fi
    if [[ -f "go.mod" ]]; then
        project_types+=("Go")
    fi
    if [[ -f "Cargo.toml" ]]; then
        project_types+=("Rust")
    fi
    if [[ -f "Gemfile" ]]; then
        project_types+=("Ruby")
    fi
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        project_types+=("Java")
    fi
    if [[ -f "composer.json" ]]; then
        project_types+=("PHP")
    fi
    
    echo -e "${GREEN}✓${NC} Project name: ${BOLD}$project_name${NC}"
    
    if [[ ${#project_types[@]} -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} Detected project types:"
        for type in "${project_types[@]}"; do
            echo -e "  ${CYAN}•${NC} $type"
        done
    else
        echo -e "${YELLOW}⚠${NC} No specific project type detected"
    fi
    
    echo ""
}

# Backup existing configuration
backup_existing() {
    if [[ -f "$CONFIG_FILE" ]] || [[ -f "${DEVCONTAINER_DIR}/devcontainer.json" ]]; then
        echo -e "${YELLOW}Found existing configuration files${NC}"
        read -p "Backup existing configuration? (y/n) " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p "$BACKUP_DIR"
            local timestamp=$(date +%Y%m%d_%H%M%S)
            
            [[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "${BACKUP_DIR}/config.yaml.${timestamp}"
            [[ -f "${DEVCONTAINER_DIR}/devcontainer.json" ]] && cp "${DEVCONTAINER_DIR}/devcontainer.json" "${BACKUP_DIR}/devcontainer.json.${timestamp}"
            
            echo -e "${GREEN}✓${NC} Backup created in ${BACKUP_DIR}"
        fi
        echo ""
    fi
}

# Configure user settings
configure_user() {
    echo -e "${BLUE}${BOLD}User Configuration${NC}"
    echo ""
    
    # Username
    local default_user=${USER:-developer}
    read -p "Container username [${default_user}]: " username
    username=${username:-$default_user}
    
    # Timezone
    local default_tz=$(timedatectl show -p Timezone --value 2>/dev/null || echo "UTC")
    read -p "Timezone [${default_tz}]: " timezone
    timezone=${timezone:-$default_tz}
    
    # Locale
    local default_locale=${LANG:-en_US.UTF-8}
    read -p "Locale [${default_locale}]: " locale
    locale=${locale:-$default_locale}
    
    # Dotfiles
    read -p "Dotfiles repository (optional): " dotfiles_repo
    
    echo ""
    
    # Save to environment
    export DEVCONTAINER_USERNAME="$username"
    export DEVCONTAINER_TIMEZONE="$timezone"
    export DEVCONTAINER_LOCALE="$locale"
    export DEVCONTAINER_DOTFILES="$dotfiles_repo"
}

# Configure features
configure_features() {
    echo -e "${BLUE}${BOLD}Feature Configuration${NC}"
    echo ""
    
    # Auto-updates
    read -p "Enable automatic tool updates? (Y/n) " -n 1 -r
    echo
    local auto_update="true"
    [[ $REPLY =~ ^[Nn]$ ]] && auto_update="false"
    
    # Security scanning
    read -p "Enable security scanning? (Y/n) " -n 1 -r
    echo
    local security_scan="true"
    [[ $REPLY =~ ^[Nn]$ ]] && security_scan="false"
    
    # Optional extensions
    echo -e "\n${CYAN}Optional VS Code Extensions:${NC}"
    echo "1) Claude Code (AI assistant - requires subscription)"
    echo "2) GitHub Copilot (AI pair programmer - requires subscription)"
    echo "3) Remote Repositories"
    echo "4) IntelliCode"
    echo "5) Spell Checker"
    echo "6) All of the above"
    echo "0) None"
    
    read -p "Select extensions (comma-separated, e.g., 1,2,3): " extension_choices
    
    local optional_extensions=""
    if [[ "$extension_choices" == "6" ]]; then
        optional_extensions="all"
    elif [[ "$extension_choices" != "0" ]]; then
        IFS=',' read -ra choices <<< "$extension_choices"
        for choice in "${choices[@]}"; do
            case $choice in
                1) optional_extensions="${optional_extensions}anthropic.claude-code,";;
                2) optional_extensions="${optional_extensions}github.copilot,";;
                3) optional_extensions="${optional_extensions}ms-vscode.remote-repositories,";;
                4) optional_extensions="${optional_extensions}visualstudioexptteam.vscodeintellicode,";;
                5) optional_extensions="${optional_extensions}streetsidesoftware.code-spell-checker,";;
            esac
        done
        optional_extensions=${optional_extensions%,}  # Remove trailing comma
    fi
    
    echo ""
    
    # Save to environment
    export DEVCONTAINER_AUTO_UPDATE="$auto_update"
    export DEVCONTAINER_SECURITY_SCAN="$security_scan"
    export DEVCONTAINER_OPTIONAL_EXTENSIONS="$optional_extensions"
}

# Generate configuration files
generate_config() {
    echo -e "${BLUE}${BOLD}Generating Configuration...${NC}"
    echo ""
    
    # Create config.yaml
    cat > "$CONFIG_FILE" << EOF
# Universal Dev Container Configuration
# Generated by setup wizard on $(date)

user:
  username: ${DEVCONTAINER_USERNAME}
  timezone: ${DEVCONTAINER_TIMEZONE}
  locale: ${DEVCONTAINER_LOCALE}
  dotfiles:
    repository: ${DEVCONTAINER_DOTFILES}

features:
  auto_update:
    enabled: ${DEVCONTAINER_AUTO_UPDATE}
    check_interval_hours: 24
  
  security_scan:
    enabled: ${DEVCONTAINER_SECURITY_SCAN}
    on_startup: true
  
  telemetry:
    enabled: false

extensions:
  optional_install: "${DEVCONTAINER_OPTIONAL_EXTENSIONS}"

environment:
  default:
    EDITOR: vim
    PAGER: less
EOF
    
    echo -e "${GREEN}✓${NC} Created config.yaml"
    
    # Create or update devcontainer.json
    if [[ ! -f "${DEVCONTAINER_DIR}/devcontainer.json" ]]; then
        cp "${DEVCONTAINER_DIR}/devcontainer.universal.json" "${DEVCONTAINER_DIR}/devcontainer.json"
        echo -e "${GREEN}✓${NC} Created devcontainer.json"
    else
        echo -e "${YELLOW}!${NC} devcontainer.json already exists (not modified)"
    fi
    
    echo ""
}

# Show next steps
show_next_steps() {
    echo -e "${GREEN}${BOLD}Setup Complete!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. ${BOLD}Open in VS Code:${NC} code ."
    echo "2. ${BOLD}Reopen in Container:${NC} When prompted, click 'Reopen in Container'"
    echo "3. ${BOLD}Wait for setup:${NC} The container will build and configure itself"
    echo ""
    echo -e "${CYAN}Useful commands once in the container:${NC}"
    echo "• ${BOLD}dev-update${NC} - Update tools and extensions"
    echo "• ${BOLD}dev-scan${NC} - Run security scan"
    echo "• ${BOLD}dev-extensions${NC} - Reinstall extensions"
    echo ""
    echo -e "${CYAN}Configuration files:${NC}"
    echo "• ${BOLD}.devcontainer/config.yaml${NC} - Your settings"
    echo "• ${BOLD}.devcontainer/devcontainer.json${NC} - Container configuration"
    echo ""
}

# Main wizard flow
main() {
    show_welcome
    
    # Check if we're in a project directory
    if [[ ! -d ".git" ]] && [[ ! -f "package.json" ]] && [[ ! -f "requirements.txt" ]] && [[ ! -f "go.mod" ]]; then
        echo -e "${YELLOW}Warning:${NC} This doesn't appear to be a project directory."
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
        echo ""
    fi
    
    detect_project
    backup_existing
    configure_user
    configure_features
    generate_config
    show_next_steps
}

# Run the wizard
main
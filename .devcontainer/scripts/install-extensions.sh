#!/bin/bash
# VS Code Extension Installer with Auto-detection
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/../config.yaml}"
VSCODE_SERVER_DIR="${HOME}/.vscode-server"
EXTENSIONS_DIR="${VSCODE_SERVER_DIR}/extensions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[Extension Installer]${NC} $1"
}

error() {
    echo -e "${RED}[Extension Installer]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[Extension Installer]${NC} $1"
}

# Parse YAML config
parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
         -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
         -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
        }
    }'
}

# Detect project type
detect_project_type() {
    local project_types=()
    
    # JavaScript/Node.js
    if [[ -f "package.json" ]] || [[ -f ".nvmrc" ]] || [[ -f "yarn.lock" ]] || [[ -f "pnpm-lock.yaml" ]]; then
        project_types+=("javascript")
    fi
    
    # Python
    if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]] || [[ -f "Pipfile" ]]; then
        project_types+=("python")
    fi
    
    # Go
    if [[ -f "go.mod" ]] || [[ -f "go.sum" ]]; then
        project_types+=("go")
    fi
    
    # Rust
    if [[ -f "Cargo.toml" ]] || [[ -f "Cargo.lock" ]]; then
        project_types+=("rust")
    fi
    
    # Docker
    if [[ -f "Dockerfile" ]] || [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]; then
        project_types+=("docker")
    fi
    
    echo "${project_types[@]}"
}

# Install extension
install_extension() {
    local extension_id=$1
    local extension_name=$(echo $extension_id | cut -d'.' -f2)
    
    # Check if already installed
    if [[ -d "${EXTENSIONS_DIR}/${extension_id}"* ]]; then
        log "Extension $extension_id is already installed"
        return 0
    fi
    
    log "Installing extension: $extension_id"
    
    # Try to download from marketplace
    local vsix_url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$(echo $extension_id | cut -d'.' -f1)/vsextensions/$(echo $extension_id | cut -d'.' -f2)/latest/vspackage"
    local vsix_file="/tmp/${extension_id}.vsix"
    
    if curl -sSL -o "$vsix_file" "$vsix_url"; then
        # Extract the extension
        local extract_dir="${EXTENSIONS_DIR}/${extension_id}-temp"
        mkdir -p "$extract_dir"
        
        if unzip -q "$vsix_file" -d "$extract_dir" 2>/dev/null; then
            # Find the actual extension directory
            local actual_dir=$(find "$extract_dir" -name "package.json" -type f | head -1 | xargs dirname)
            if [[ -n "$actual_dir" ]]; then
                mv "$actual_dir" "${EXTENSIONS_DIR}/${extension_id}"
                rm -rf "$extract_dir"
                log "Successfully installed $extension_id"
            else
                error "Failed to find extension content in $vsix_file"
                rm -rf "$extract_dir"
            fi
        else
            error "Failed to extract $vsix_file"
        fi
        
        rm -f "$vsix_file"
    else
        error "Failed to download extension $extension_id"
        return 1
    fi
}

# Main installation logic
main() {
    log "Starting extension installation..."
    
    # Ensure extensions directory exists
    mkdir -p "$EXTENSIONS_DIR"
    
    # Load configuration
    if [[ -f "$CONFIG_FILE" ]]; then
        eval $(parse_yaml "$CONFIG_FILE" "config_")
    else
        warning "Configuration file not found at $CONFIG_FILE"
    fi
    
    # Detect project type
    log "Detecting project type..."
    project_types=($(detect_project_type))
    
    if [[ ${#project_types[@]} -eq 0 ]]; then
        log "No specific project type detected, installing only core extensions"
    else
        log "Detected project types: ${project_types[*]}"
    fi
    
    # Install core extensions
    log "Installing core extensions..."
    core_extensions=(
        "ms-vsliveshare.vsliveshare"
        "mhutchie.git-graph"
        "eamodio.gitlens"
    )
    
    for ext in "${core_extensions[@]}"; do
        install_extension "$ext" || warning "Failed to install $ext"
    done
    
    # Install project-specific extensions
    for project_type in "${project_types[@]}"; do
        log "Installing extensions for $project_type..."
        
        case "$project_type" in
            javascript)
                install_extension "dbaeumer.vscode-eslint" || true
                install_extension "esbenp.prettier-vscode" || true
                ;;
            python)
                install_extension "ms-python.python" || true
                install_extension "ms-python.vscode-pylance" || true
                install_extension "ms-python.black-formatter" || true
                ;;
            go)
                install_extension "golang.go" || true
                ;;
            rust)
                install_extension "rust-lang.rust-analyzer" || true
                ;;
            docker)
                install_extension "ms-azuretools.vscode-docker" || true
                ;;
        esac
    done
    
    # Check for user-requested optional extensions
    if [[ -n "${INSTALL_OPTIONAL_EXTENSIONS:-}" ]]; then
        log "Installing optional extensions..."
        optional_extensions=(
            "anthropic.claude-code"
            "github.copilot"
            "github.copilot-chat"
            "ms-vscode.remote-repositories"
            "visualstudioexptteam.vscodeintellicode"
            "streetsidesoftware.code-spell-checker"
        )
        
        for ext in "${optional_extensions[@]}"; do
            if [[ "${INSTALL_OPTIONAL_EXTENSIONS}" == *"$ext"* ]] || [[ "${INSTALL_OPTIONAL_EXTENSIONS}" == "all" ]]; then
                install_extension "$ext" || warning "Failed to install optional extension $ext"
            fi
        done
    fi
    
    log "Extension installation completed!"
    
    # Update extension cache timestamp
    touch "${EXTENSIONS_DIR}/.last-update"
}

# Run main function
main "$@"
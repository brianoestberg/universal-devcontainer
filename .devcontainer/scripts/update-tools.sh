#!/bin/bash
# Auto-update mechanism for development tools
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/../config.yaml}"
UPDATE_CACHE_DIR="${HOME}/.config/devcontainer/update-cache"
UPDATE_LOG="${UPDATE_CACHE_DIR}/update.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[Auto-Update]${NC} $1" | tee -a "$UPDATE_LOG"
}

error() {
    echo -e "${RED}[Auto-Update]${NC} $1" >&2 | tee -a "$UPDATE_LOG"
}

warning() {
    echo -e "${YELLOW}[Auto-Update]${NC} $1" | tee -a "$UPDATE_LOG"
}

info() {
    echo -e "${BLUE}[Auto-Update]${NC} $1" | tee -a "$UPDATE_LOG"
}

# Create cache directory
mkdir -p "$UPDATE_CACHE_DIR"

# Get latest version from GitHub API
get_github_latest_version() {
    local repo=$1
    curl -s "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name' | sed 's/^v//'
}

# Check if update is needed
needs_update() {
    local tool=$1
    local current_version=$2
    local latest_version=$3
    local cache_file="${UPDATE_CACHE_DIR}/${tool}.version"
    
    # Check if we've already updated to this version
    if [[ -f "$cache_file" ]]; then
        local cached_version=$(cat "$cache_file")
        if [[ "$cached_version" == "$latest_version" ]]; then
            return 1
        fi
    fi
    
    # Compare versions
    if [[ "$current_version" != "$latest_version" ]]; then
        return 0
    fi
    
    return 1
}

# Update git-delta
update_delta() {
    log "Checking git-delta for updates..."
    
    local current_version=$(delta --version 2>/dev/null | grep -oP 'delta \K[0-9.]+' || echo "0.0.0")
    local latest_version=$(get_github_latest_version "dandavison/delta")
    
    if needs_update "delta" "$current_version" "$latest_version"; then
        log "Updating git-delta from $current_version to $latest_version..."
        
        local arch=$(dpkg --print-architecture)
        local deb_url="https://github.com/dandavison/delta/releases/download/$latest_version/git-delta_${latest_version}_${arch}.deb"
        local temp_file="/tmp/git-delta_${latest_version}_${arch}.deb"
        
        if wget -q -O "$temp_file" "$deb_url"; then
            sudo dpkg -i "$temp_file"
            rm -f "$temp_file"
            echo "$latest_version" > "${UPDATE_CACHE_DIR}/delta.version"
            log "Successfully updated git-delta to $latest_version"
        else
            error "Failed to download git-delta $latest_version"
        fi
    else
        info "git-delta is up to date ($current_version)"
    fi
}

# Update GitHub CLI
update_gh() {
    log "Checking GitHub CLI for updates..."
    
    local current_version=$(gh --version 2>/dev/null | grep -oP 'gh version \K[0-9.]+' || echo "0.0.0")
    
    # Update via apt
    sudo apt-get update -qq
    local available_version=$(apt-cache policy gh | grep Candidate | awk '{print $2}' | cut -d'-' -f1)
    
    if [[ -n "$available_version" ]] && [[ "$current_version" != "$available_version" ]]; then
        log "Updating GitHub CLI from $current_version to $available_version..."
        sudo apt-get install -y gh
        echo "$available_version" > "${UPDATE_CACHE_DIR}/gh.version"
        log "Successfully updated GitHub CLI to $available_version"
    else
        info "GitHub CLI is up to date ($current_version)"
    fi
}

# Update VS Code extensions
update_extensions() {
    log "Checking VS Code extensions for updates..."
    
    local extensions_dir="${HOME}/.vscode-server/extensions"
    local update_count=0
    
    if [[ -d "$extensions_dir" ]]; then
        for ext_dir in "$extensions_dir"/*; do
            if [[ -d "$ext_dir" ]] && [[ -f "$ext_dir/package.json" ]]; then
                local ext_id=$(jq -r '.publisher + "." + .name' "$ext_dir/package.json" 2>/dev/null || continue)
                local current_version=$(jq -r '.version' "$ext_dir/package.json" 2>/dev/null || continue)
                
                # Check marketplace for latest version
                local marketplace_info=$(curl -s "https://marketplace.visualstudio.com/items?itemName=$ext_id" | grep -oP '"version":"\K[^"]+' | head -1)
                
                if [[ -n "$marketplace_info" ]] && [[ "$current_version" != "$marketplace_info" ]]; then
                    log "Extension $ext_id has update available: $current_version -> $marketplace_info"
                    
                    # Re-install the extension to get the latest version
                    "${SCRIPT_DIR}/install-extensions.sh" "$ext_id"
                    ((update_count++))
                fi
            fi
        done
        
        if [[ $update_count -eq 0 ]]; then
            info "All VS Code extensions are up to date"
        else
            log "Updated $update_count VS Code extensions"
        fi
    fi
}

# Update system packages
update_system() {
    log "Checking system packages for updates..."
    
    # Update package lists
    sudo apt-get update -qq
    
    # Check for upgradable packages
    local upgradable=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)
    
    if [[ $upgradable -gt 0 ]]; then
        log "Found $upgradable upgradable packages"
        
        # Perform safe upgrades only
        sudo apt-get upgrade -y --no-install-recommends
        sudo apt-get autoremove -y
        sudo apt-get clean
        
        log "System packages updated"
    else
        info "All system packages are up to date"
    fi
}

# Clean old cache
clean_cache() {
    log "Cleaning old cache files..."
    
    # Remove cache files older than 30 days
    find "$UPDATE_CACHE_DIR" -type f -mtime +30 -delete
    
    # Clean apt cache
    sudo apt-get clean
    
    # Clean pip cache if Python is installed
    if command -v pip &> /dev/null; then
        pip cache purge 2>/dev/null || true
    fi
    
    # Clean npm cache if Node.js is installed
    if command -v npm &> /dev/null; then
        npm cache clean --force 2>/dev/null || true
    fi
}

# Check last update time
should_check_updates() {
    local check_interval_hours=${AUTO_UPDATE_CHECK_INTERVAL:-24}
    local last_check_file="${UPDATE_CACHE_DIR}/.last-check"
    
    if [[ ! -f "$last_check_file" ]]; then
        return 0
    fi
    
    local last_check=$(stat -c %Y "$last_check_file" 2>/dev/null || echo 0)
    local current_time=$(date +%s)
    local hours_since_check=$(( (current_time - last_check) / 3600 ))
    
    if [[ $hours_since_check -ge $check_interval_hours ]]; then
        return 0
    fi
    
    return 1
}

# Main update function
main() {
    log "Starting automatic updates ($(date))"
    
    # Check if updates should be performed
    if ! should_check_updates; then
        info "Skipping update check (not due yet)"
        exit 0
    fi
    
    # Mark update check time
    touch "${UPDATE_CACHE_DIR}/.last-check"
    
    # Perform updates
    update_system
    update_delta
    update_gh
    update_extensions
    
    # Clean cache
    clean_cache
    
    log "Update check completed"
    
    # Schedule next update if running in background
    if [[ "${RUN_IN_BACKGROUND:-false}" == "true" ]]; then
        log "Scheduling next update check in 24 hours"
        (sleep 86400 && "$0" --background) &
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --background)
            RUN_IN_BACKGROUND=true
            shift
            ;;
        --force)
            rm -f "${UPDATE_CACHE_DIR}/.last-check"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Run main function
main
#!/bin/bash
# Security scanning tools for dev containers
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAN_RESULTS_DIR="${HOME}/.config/devcontainer/security-scans"
SCAN_LOG="${SCAN_RESULTS_DIR}/scan.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[Security]${NC} $1" | tee -a "$SCAN_LOG"
}

error() {
    echo -e "${RED}[Security]${NC} $1" >&2 | tee -a "$SCAN_LOG"
}

warning() {
    echo -e "${YELLOW}[Security]${NC} $1" | tee -a "$SCAN_LOG"
}

info() {
    echo -e "${BLUE}[Security]${NC} $1" | tee -a "$SCAN_LOG"
}

# Create results directory
mkdir -p "$SCAN_RESULTS_DIR"

# Install security tools if not present
install_security_tools() {
    log "Checking security tools..."
    
    # Install Trivy for container scanning
    if ! command -v trivy &> /dev/null; then
        log "Installing Trivy..."
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    fi
    
    # Install hadolint for Dockerfile linting
    if ! command -v hadolint &> /dev/null; then
        log "Installing hadolint..."
        local hadolint_version="2.12.0"
        wget -q -O /usr/local/bin/hadolint "https://github.com/hadolint/hadolint/releases/download/v${hadolint_version}/hadolint-Linux-x86_64"
        chmod +x /usr/local/bin/hadolint
    fi
    
    # Install shellcheck for shell script linting
    if ! command -v shellcheck &> /dev/null; then
        log "Installing shellcheck..."
        sudo apt-get update -qq && sudo apt-get install -y shellcheck
    fi
    
    # Install git-secrets for preventing secrets in commits
    if ! command -v git-secrets &> /dev/null; then
        log "Installing git-secrets..."
        git clone https://github.com/awslabs/git-secrets.git /tmp/git-secrets
        cd /tmp/git-secrets && sudo make install
        rm -rf /tmp/git-secrets
    fi
}

# Scan Dockerfile
scan_dockerfile() {
    log "Scanning Dockerfiles..."
    
    local dockerfiles=$(find . -name "Dockerfile*" -type f 2>/dev/null | grep -v node_modules | grep -v .git)
    
    if [[ -z "$dockerfiles" ]]; then
        info "No Dockerfiles found to scan"
        return
    fi
    
    local issues_found=0
    
    while IFS= read -r dockerfile; do
        log "  Scanning $dockerfile"
        
        if hadolint "$dockerfile" > "${SCAN_RESULTS_DIR}/hadolint-$(basename $dockerfile).txt" 2>&1; then
            info "  ✓ No issues found in $dockerfile"
        else
            warning "  ⚠ Issues found in $dockerfile (see ${SCAN_RESULTS_DIR}/hadolint-$(basename $dockerfile).txt)"
            ((issues_found++))
        fi
    done <<< "$dockerfiles"
    
    if [[ $issues_found -gt 0 ]]; then
        warning "Found issues in $issues_found Dockerfile(s)"
    fi
}

# Scan shell scripts
scan_shell_scripts() {
    log "Scanning shell scripts..."
    
    local scripts=$(find . -name "*.sh" -type f 2>/dev/null | grep -v node_modules | grep -v .git)
    
    if [[ -z "$scripts" ]]; then
        info "No shell scripts found to scan"
        return
    fi
    
    local issues_found=0
    
    while IFS= read -r script; do
        log "  Scanning $script"
        
        if shellcheck "$script" > "${SCAN_RESULTS_DIR}/shellcheck-$(basename $script).txt" 2>&1; then
            info "  ✓ No issues found in $script"
        else
            warning "  ⚠ Issues found in $script (see ${SCAN_RESULTS_DIR}/shellcheck-$(basename $script).txt)"
            ((issues_found++))
        fi
    done <<< "$scripts"
    
    if [[ $issues_found -gt 0 ]]; then
        warning "Found issues in $issues_found shell script(s)"
    fi
}

# Scan for secrets
scan_for_secrets() {
    log "Scanning for secrets..."
    
    # Initialize git-secrets if in a git repo
    if [[ -d .git ]]; then
        git secrets --install -f &>/dev/null || true
        git secrets --register-aws &>/dev/null || true
        
        # Add custom patterns
        git secrets --add 'api[_-]?key.*[:=]\s*.+' &>/dev/null || true
        git secrets --add 'secret.*[:=]\s*.+' &>/dev/null || true
        git secrets --add 'password.*[:=]\s*.+' &>/dev/null || true
        git secrets --add 'token.*[:=]\s*.+' &>/dev/null || true
        
        if git secrets --scan > "${SCAN_RESULTS_DIR}/git-secrets.txt" 2>&1; then
            info "✓ No secrets found in git repository"
        else
            error "⚠ Potential secrets found! Check ${SCAN_RESULTS_DIR}/git-secrets.txt"
        fi
    else
        info "Not a git repository, skipping git-secrets scan"
    fi
    
    # Also scan common files for secrets
    local sensitive_patterns=(
        "PRIVATE KEY"
        "BEGIN RSA"
        "BEGIN DSA"
        "BEGIN EC"
        "BEGIN OPENSSH"
        "api_key"
        "apikey"
        "access_token"
        "secret"
        "password"
    )
    
    log "  Scanning common files for sensitive patterns..."
    local files_to_scan=$(find . -type f \( -name "*.env*" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.conf" -o -name "*.config" \) 2>/dev/null | grep -v node_modules | grep -v .git | head -100)
    
    local secrets_found=0
    while IFS= read -r file; do
        for pattern in "${sensitive_patterns[@]}"; do
            if grep -i "$pattern" "$file" &>/dev/null; then
                warning "  ⚠ Potential sensitive data in $file (pattern: $pattern)"
                ((secrets_found++))
                break
            fi
        done
    done <<< "$files_to_scan"
    
    if [[ $secrets_found -eq 0 ]]; then
        info "  ✓ No sensitive patterns found in configuration files"
    fi
}

# Scan container image
scan_container() {
    log "Scanning container image for vulnerabilities..."
    
    # Get current container image
    local image_name="${DEVCONTAINER_IMAGE:-ubuntu:22.04}"
    
    if command -v trivy &> /dev/null; then
        log "  Running Trivy scan on $image_name..."
        
        if trivy image --severity HIGH,CRITICAL "$image_name" > "${SCAN_RESULTS_DIR}/trivy-container.txt" 2>&1; then
            info "  ✓ Container scan completed (see ${SCAN_RESULTS_DIR}/trivy-container.txt)"
        else
            warning "  ⚠ Vulnerabilities found in container image"
        fi
    else
        warning "Trivy not available, skipping container scan"
    fi
}

# Check file permissions
check_permissions() {
    log "Checking file permissions..."
    
    # Find files with overly permissive permissions
    local world_writable=$(find . -type f -perm -002 2>/dev/null | grep -v node_modules | grep -v .git | head -20)
    
    if [[ -n "$world_writable" ]]; then
        warning "Found world-writable files:"
        echo "$world_writable" | while IFS= read -r file; do
            warning "  ⚠ $file"
        done
    else
        info "✓ No world-writable files found"
    fi
    
    # Check for setuid/setgid files
    local setuid_files=$(find . -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | grep -v node_modules | grep -v .git)
    
    if [[ -n "$setuid_files" ]]; then
        warning "Found setuid/setgid files:"
        echo "$setuid_files" | while IFS= read -r file; do
            warning "  ⚠ $file"
        done
    else
        info "✓ No setuid/setgid files found"
    fi
}

# Generate security report
generate_report() {
    local report_file="${SCAN_RESULTS_DIR}/security-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Security Scan Report"
        echo "===================="
        echo "Date: $(date)"
        echo "Directory: $(pwd)"
        echo ""
        echo "Scan Results:"
        echo "-------------"
        
        # Summary of findings
        local total_files=$(find "${SCAN_RESULTS_DIR}" -name "*.txt" -mtime -1 | wc -l)
        echo "Total scans performed: $total_files"
        
        # List all result files
        echo ""
        echo "Detailed results in:"
        find "${SCAN_RESULTS_DIR}" -name "*.txt" -mtime -1 | while read -r file; do
            echo "  - $file"
        done
        
    } > "$report_file"
    
    log "Security report generated: $report_file"
}

# Main function
main() {
    log "Starting security scan ($(date))"
    
    # Install tools if needed
    install_security_tools
    
    # Run scans
    scan_dockerfile
    scan_shell_scripts
    scan_for_secrets
    scan_container
    check_permissions
    
    # Generate report
    generate_report
    
    log "Security scan completed"
}

# Parse arguments
SCAN_TYPE="all"
while [[ $# -gt 0 ]]; do
    case $1 in
        --dockerfile)
            SCAN_TYPE="dockerfile"
            shift
            ;;
        --secrets)
            SCAN_TYPE="secrets"
            shift
            ;;
        --container)
            SCAN_TYPE="container"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Run appropriate scan
case $SCAN_TYPE in
    dockerfile)
        scan_dockerfile
        ;;
    secrets)
        scan_for_secrets
        ;;
    container)
        scan_container
        ;;
    all)
        main
        ;;
esac
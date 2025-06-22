#!/usr/bin/env bash
set -euo pipefail

# This script pre-caches firewall IPs at build time
CACHE_DIR="/tmp/firewall-cache"
CACHE_FILE="$CACHE_DIR/allowed-ips"

mkdir -p "$CACHE_DIR"

# Function to fetch and cache IPs
cache_ips() {
    echo "Pre-caching firewall IPs..."
    
    # Temporarily create ipset for collection
    ipset create temp-allowed hash:net family inet hashsize 4096 maxelem 65536 2>/dev/null || true
    
    # GitHub IP ranges (using API)
    if command -v curl &> /dev/null; then
        echo "Fetching GitHub IP ranges..."
        GITHUB_META=$(curl -s https://api.github.com/meta || echo '{}')
        
        # Extract and add GitHub IPs
        echo "$GITHUB_META" | jq -r '.actions[]? // empty' | while read -r range; do
            ipset add temp-allowed "$range" -exist 2>/dev/null || true
        done
        
        echo "$GITHUB_META" | jq -r '.web[]? // empty' | while read -r range; do
            ipset add temp-allowed "$range" -exist 2>/dev/null || true
        done
        
        echo "$GITHUB_META" | jq -r '.api[]? // empty' | while read -r range; do
            ipset add temp-allowed "$range" -exist 2>/dev/null || true
        done
    fi
    
    # Essential domains
    ESSENTIAL_DOMAINS=(
        "registry.npmjs.org"
        "api.anthropic.com"
        "sentry.io"
        "statsig.anthropic.com"
        "statsig.com"
        "github.com"
        "api.github.com"
        "raw.githubusercontent.com"
        "marketplace.visualstudio.com"
    )
    
    for domain in "${ESSENTIAL_DOMAINS[@]}"; do
        echo "Resolving $domain..."
        # Use multiple DNS resolvers for reliability
        for resolver in "8.8.8.8" "1.1.1.1" "9.9.9.9"; do
            dig +short "@$resolver" "$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | while read -r ip; do
                ipset add temp-allowed "$ip/32" -exist 2>/dev/null || true
            done
        done
    done
    
    # Save to cache file
    ipset list temp-allowed | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' > "$CACHE_FILE" || true
    
    # Cleanup
    ipset destroy temp-allowed 2>/dev/null || true
    
    echo "Cached $(wc -l < "$CACHE_FILE" 2>/dev/null || echo 0) IP addresses"
}

# Run caching
cache_ips
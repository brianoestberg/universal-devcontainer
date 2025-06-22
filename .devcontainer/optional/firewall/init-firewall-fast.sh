#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Fast firewall initialization with pre-cached IPs
CACHE_DIR="/tmp/firewall-cache"
CACHE_FILE="$CACHE_DIR/allowed-ips"
CACHE_AGE=43200  # 12 hours in seconds

# Function to check if cache is valid
is_cache_valid() {
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
        [[ $cache_age -lt $CACHE_AGE ]]
    else
        return 1
    fi
}

# Fast setup using cache
fast_setup() {
    echo "Fast firewall setup starting..."
    
    # Reset firewall rules
    iptables -F 2>/dev/null || true
    iptables -X 2>/dev/null || true
    iptables -t nat -F 2>/dev/null || true
    iptables -t nat -X 2>/dev/null || true
    iptables -t mangle -F 2>/dev/null || true
    iptables -t mangle -X 2>/dev/null || true
    
    # Destroy old ipset if exists
    ipset destroy allowed-domains 2>/dev/null || true
    
    # Essential rules that don't require domain resolution
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    iptables -A INPUT  -p udp --sport 53 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT  -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
    iptables -A INPUT  -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Create ipset
    ipset create allowed-domains hash:net family inet hashsize 4096 maxelem 65536
    
    # Load from cache if valid
    if is_cache_valid; then
        echo "Loading from cache ($(wc -l < "$CACHE_FILE") IPs)..."
        while IFS= read -r ip; do
            ipset add allowed-domains "$ip" -exist 2>/dev/null || true
        done < "$CACHE_FILE"
    else
        echo "Cache invalid, using minimal ruleset..."
        # Just add essential IPs for basic functionality
        ipset add allowed-domains 140.82.112.0/20 -exist  # GitHub
        ipset add allowed-domains 185.199.108.0/22 -exist # GitHub
        ipset add allowed-domains 104.16.0.0/12 -exist    # Cloudflare (npm)
    fi
    
    # Apply ipset rules
    iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
    iptables -A INPUT  -m set --match-set allowed-domains src -j ACCEPT
    
    # Default policies
    iptables -P INPUT   DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT  DROP
    
    echo "Firewall setup complete (fast mode)"
}

# Run fast setup
fast_setup

# Update cache in background if needed
if ! is_cache_valid; then
    echo "Updating cache in background..."
    nohup /usr/local/bin/firewall-cache-updater.sh > /tmp/cache-update.log 2>&1 &
fi
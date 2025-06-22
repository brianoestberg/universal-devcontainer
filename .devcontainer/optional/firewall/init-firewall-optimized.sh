#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Cache file for IP addresses (12 hour cache)
CACHE_DIR="/tmp/firewall-cache"
CACHE_FILE="$CACHE_DIR/allowed-ips"
CACHE_AGE=43200  # 12 hours in seconds

# Create cache directory
mkdir -p "$CACHE_DIR"

# Function to check if cache is valid
is_cache_valid() {
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
        [[ $cache_age -lt $CACHE_AGE ]]
    else
        return 1
    fi
}

# Function to load from cache
load_from_cache() {
    echo "Loading firewall rules from cache..."
    while IFS= read -r ip; do
        ipset add allowed-domains "$ip" -exist
    done < "$CACHE_FILE"
    echo "Loaded $(wc -l < "$CACHE_FILE") IP addresses from cache"
}

# Function to save to cache
save_to_cache() {
    ipset list allowed-domains | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' > "$CACHE_FILE"
}

# ───────────────────────────────────────────────────────── Reset
iptables -F; iptables -X
iptables -t nat    -F; iptables -t nat    -X
iptables -t mangle -F; iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true

# ─────────────────────────────────────────────── DNS, SSH, localhost
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT  -p udp --sport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT  -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

ipset create allowed-domains hash:net -exist

# Check if we can use cached IPs
if is_cache_valid; then
    load_from_cache
else
    echo "Cache invalid or missing, fetching fresh IP addresses..."
    
    # ─────────────────────────────────────── GitHub-CIDR (IPv4 only)
    echo "Fetching GitHub IP ranges..."
    gh_json="$(curl -s --connect-timeout 10 https://api.github.com/meta || echo "")"
    
    if [[ -n "$gh_json" ]]; then
        echo "Processing GitHub IPs..."
        # Only process essential GitHub IP ranges (web, api, git)
        echo "$gh_json" | jq -r '(.web + .api + .git)[]' 2>/dev/null | while read -r cidr; do
            [[ "$cidr" == *":"* ]] && continue  # skip IPv6
            echo "Adding GitHub range $cidr"
            ipset add allowed-domains "$cidr" -exist
        done
    else
        echo "WARNING: Could not fetch GitHub IPs, using fallback ranges"
        # Fallback to known GitHub ranges
        for cidr in "140.82.112.0/20" "143.55.64.0/20" "185.199.108.0/22" "192.30.252.0/22"; do
            ipset add allowed-domains "$cidr" -exist
        done
    fi
    
    # ─────────────────────────────────────── Essential domains only
    ALLOWLIST_DOMAINS=(
        registry.npmjs.org
        api.anthropic.com
        sentry.io
        statsig.anthropic.com
        statsig.com
    )
    
    echo "Resolving essential domains..."
    for domain in "${ALLOWLIST_DOMAINS[@]}"; do
        echo "Resolving $domain..."
        # Use timeout and parallel DNS resolution
        dig +short +time=2 +tries=1 A "$domain" 2>/dev/null | while read -r ip; do
            if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "Adding $ip for $domain"
                ipset add allowed-domains "$ip" -exist
            fi
        done
    done
    
    # Save to cache
    save_to_cache
fi

# ───────────────────────────────────── Host-subnet (for bind-mounts)
HOST_IP=$(ip route | awk '/default/ {print $3}')
HOST_NET=$(echo "$HOST_IP" | sed 's/\.[0-9]\+$/\.0\/24/')
echo "Host network detected as: $HOST_NET"
iptables -A INPUT  -s "$HOST_NET" -j ACCEPT
iptables -A OUTPUT -d "$HOST_NET" -j ACCEPT

# ───────────────────────────────────── Standard-politikker
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  DROP
iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

echo "Firewall configuration complete"

# ───────────────────────────────────── Quick health check
if timeout 3 curl -s https://example.com >/dev/null 2>&1; then
    echo "Firewall verification failed - able to reach blocked sites"
    exit 1
else
    echo "Firewall verification passed - unable to reach https://example.com as expected"
fi

if timeout 3 curl -s https://api.github.com/zen >/dev/null 2>&1; then
    echo "Firewall verification passed - able to reach https://api.github.com as expected"
else
    echo "WARNING: Cannot reach GitHub API"
fi
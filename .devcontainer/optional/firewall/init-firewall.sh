#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

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

ipset create allowed-domains hash:net -exist   # kan køres flere gange

# ─────────────────────────────────────── GitHub-CIDR (IPv4 only)
echo "Fetching GitHub IP ranges…"
gh_json="$(curl -s https://api.github.com/meta)"
[[ -z "$gh_json" ]] && { echo "ERROR: GitHub meta empty"; exit 1; }

echo "Adding GitHub IPv4 CIDRs…"
echo "$gh_json" | jq -r '(.web + .api + .git)[]' | while read -r cidr; do
  [[ "$cidr" == *":"* ]] && continue          # skip IPv6 ranges
  ipset add allowed-domains "$cidr" -exist
done

# ─────────────────────────────────────── Andre tilladte domæner
ALLOWLIST_DOMAINS=(
  registry.npmjs.org
  api.anthropic.com
  # VS Code Marketplace + CDN
  gallery.vsassets.io
  gallerycdn.vsassets.io
  az764295.vo.msecnd.net
  marketplace.visualstudio.com
  # Telemetry
  sentry.io
  statsig.anthropic.com
  statsig.com
)

for domain in "${ALLOWLIST_DOMAINS[@]}"; do
  echo "Resolving $domain…"
  dig +short A "$domain" | while read -r ip; do
    # spring alt der ikke er en ren IPv4-adresse over
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { 
      echo "  ↪︎ skipping non-A record: $ip"; continue; }
    ipset add allowed-domains "$ip" -exist
  done
done

# ───────────────────────────────────── Host-subnet (for bind-mounts)
HOST_IP=$(ip route | awk '/default/ {print $3}')
HOST_NET=$(echo "$HOST_IP" | sed 's/\.[0-9]\+$/\.0\/24/')
iptables -A INPUT  -s "$HOST_NET" -j ACCEPT
iptables -A OUTPUT -d "$HOST_NET" -j ACCEPT

# ───────────────────────────────────── Standard-politikker
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  DROP
iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

echo "Firewall rules applied ✔"

# ───────────────────────────────────── Health-check
curl -s --connect-timeout 5 https://api.github.com/zen >/dev/null \
  && echo "GitHub check OK" \
  || { echo "GitHub check FAILED"; exit 1; }

echo "Firewall verification completed ✅"

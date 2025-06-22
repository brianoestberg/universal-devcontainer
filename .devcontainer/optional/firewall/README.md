# Firewall Configuration (Optional)

This directory contains optional firewall scripts for enhanced network security in your dev container.

## When to Use

Enable the firewall if you need:
- Restricted network access
- Compliance with security policies
- Protection against accidental network exposure

## Setup

1. Copy the desired firewall script to your project:
   ```bash
   cp .devcontainer/optional/firewall/init-firewall-fast.sh .devcontainer/
   ```

2. Update your `config.yaml`:
   ```yaml
   features:
     firewall:
       enabled: true
   ```

3. Add to `devcontainer.json`:
   ```json
   {
     "runArgs": [
       "--cap-add=NET_ADMIN",
       "--cap-add=NET_RAW"
     ],
     "postStartCommand": "sudo /home/developer/.devcontainer/init-firewall-fast.sh"
   }
   ```

## Scripts

- `init-firewall.sh` - Basic firewall setup
- `init-firewall-optimized.sh` - Optimized with caching
- `init-firewall-fast.sh` - Fastest startup version
- `firewall-cache-updater.sh` - Cache management

## Note

The firewall is disabled by default as most development environments don't require it.
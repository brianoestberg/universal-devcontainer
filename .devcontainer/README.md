# Universal Dev Container Configuration

This directory contains the Universal Dev Container configuration files.

## Quick Setup

Run the setup wizard:
```bash
./.devcontainer/scripts/setup-wizard.sh
```

## Files

- `Dockerfile` - Universal base image (Ubuntu 22.04)
- `devcontainer.json` - VS Code dev container configuration
- `config.yaml` - User customization settings
- `scripts/` - Automation and utility scripts
- `optional/` - Optional features (e.g., firewall)

## Customization

Edit `config.yaml` to customize:
- Timezone and locale
- Optional VS Code extensions
- Auto-update preferences
- Security scanning options

## Scripts

- `setup-wizard.sh` - Interactive configuration
- `install-extensions.sh` - Smart extension management
- `update-tools.sh` - Keep tools up-to-date
- `security-scan.sh` - Security vulnerability scanning
- `dev-setup.sh` - Developer environment setup
- `install-dependencies.sh` - Auto-install project dependencies

## Commands

Once in the container:
- `dev-update` - Update tools and extensions
- `dev-scan` - Run security scan
- `dev-extensions` - Reinstall extensions

## Support

For issues or questions, see the main repository documentation.
# Canvus Server Installer

A robust installation script for setting up and managing Canvus Server installations with automatic SSL certificate handling and service management.

## Features

- Automated installation of Canvus Server
- Automatic SSL certificate management with Let's Encrypt
- Idempotent operations (safe to run multiple times)
- Comprehensive error handling and recovery
- Service status verification
- Git sync support for updates

## Prerequisites

- Ubuntu/Debian-based system
- Root or sudo access
- Public domain name (for SSL certificates)
- Port 443 available (for SSL)
- Port 80 available (for Let's Encrypt verification)

## Configuration

Before running the installer, you can configure the following variables in the script:

```bash
ADMIN_EMAIL="admin@local.local"        # Admin user email
ADMIN_PASSWORD_DEFAULT="Taction123!"   # Default admin password
FQDN_DEFAULT=""                        # Your domain name
LETS_ENCRYPT_EMAIL="mt-canvus-server-setup-script@multitaction.com"  # Let's Encrypt contact email
ACTIVATION_KEY_DEFAULT="xxxx-xxxx-xxxx-xxxx"  # Your activation key
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/CanvusServerInstaller.git
cd CanvusServerInstaller
```

2. Make the script executable:
```bash
chmod +x CanvusServerInstall.sh
```

3. Run the installer:
```bash
sudo ./CanvusServerInstall.sh
```

## SSL Certificate Management

The installer automatically:
- Obtains SSL certificates from Let's Encrypt
- Configures proper permissions
- Sets up automatic renewal
- Verifies certificate access

## Service Management

The installer handles:
- Service installation and configuration
- Automatic service startup
- Service status verification
- Graceful restarts when needed

## Error Handling

The script includes comprehensive error handling:
- Step-by-step verification
- Automatic recovery attempts
- Detailed error messages
- Safe rerun capability

## Git Sync

To keep your installation up to date, use the following git sync script:

```bash
#!/bin/bash

# Configuration
INSTALL_DIR="/path/to/your/installation"
BACKUP_DIR="/path/to/backup/directory"
BRANCH="main"

# Create backup
echo "Creating backup..."
timestamp=$(date +%Y%m%d_%H%M%S)
backup_path="$BACKUP_DIR/canvus_backup_$timestamp"
mkdir -p "$backup_path"

# Backup critical files
cp -r "$INSTALL_DIR/certs" "$backup_path/"
cp -r "$INSTALL_DIR/config" "$backup_path/"
cp "$INSTALL_DIR/mt-canvus-server.ini" "$backup_path/"

# Pull latest changes
echo "Pulling latest changes..."
cd "$INSTALL_DIR"
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

# Restore backup if needed
if [ -d "$backup_path" ]; then
    echo "Restoring backup..."
    cp -r "$backup_path/certs" "$INSTALL_DIR/"
    cp -r "$backup_path/config" "$INSTALL_DIR/"
    cp "$backup_path/mt-canvus-server.ini" "$INSTALL_DIR/"
fi

# Run installer
echo "Running installer..."
sudo ./CanvusServerInstall.sh

echo "Sync completed. Please check the logs for any warnings or errors."
```

## Troubleshooting

1. SSL Certificate Issues:
   - Verify domain DNS settings
   - Check certificate permissions
   - Ensure ports 80 and 443 are accessible

2. Service Issues:
   - Check service logs: `journalctl -u mt-canvus-server`
   - Verify service status: `systemctl status mt-canvus-server`
   - Check permissions on configuration files

3. Database Issues:
   - Verify PostgreSQL is running
   - Check database permissions
   - Review database logs

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

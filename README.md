# Canvus Server Installer

A robust installation script for setting up and managing Canvus Server installations with automatic SSL certificate handling and service management.

## ⚠️ Important Notice

**Windows Installer Status**: The Windows PowerShell installer is currently under testing. While functional, it should be used with caution in production environments. Please test thoroughly in staging environments before production deployment.

## Features

- Automated installation of Canvus Server
- Automatic SSL certificate management with Let's Encrypt
- Idempotent operations (safe to run multiple times)
- Comprehensive error handling and recovery
- Service status verification
- Git sync support for updates
- **NEW: Windows PowerShell installer for Windows 11, Server 2016, and Server 2022** ⚠️ *Under Testing*

## Supported Platforms

### Linux (Ubuntu/Debian)
- Ubuntu 18.04 and later
- Debian-based systems
- Uses bash script: `CanvusServerInstall.sh`

### Windows
- Windows 11
- Windows Server 2016
- Windows Server 2022
- Uses PowerShell script: `CanvusServerInstall.ps1`

## Quick Start

### Linux Installation

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

### Windows Installation

1. Clone the repository:
```powershell
git clone https://github.com/yourusername/CanvusServerInstaller.git
cd CanvusServerInstaller
```

2. Run the installer (as Administrator):
```powershell
# Using PowerShell directly
.\CanvusServerInstall.ps1

# Or using the batch wrapper
.\Install-CanvusServer.bat
```

3. For SSL setup, provide your domain:
```powershell
.\CanvusServerInstall.ps1 -FQDN "canvus.example.com" -LetsEncryptEmail "admin@example.com" -DownloadUrl "https://example.com/mt-canvus-server-windows.zip"
```

**Note**: The installer now includes the official download URL by default.

## Prerequisites

### Linux
- Ubuntu/Debian-based system
- Root or sudo access
- Public domain name (for SSL certificates)
- Port 443 available (for SSL)
- Port 80 available (for Let's Encrypt verification)

### Windows
- Windows 11, Server 2016, or Server 2022
- Administrative privileges
- PowerShell 5.1 or later
- Internet connectivity for package downloads
- Public domain name (for SSL certificates)
- Port 443 available (for SSL)
- Port 80 available (for Let's Encrypt verification)

## Configuration

Before running the installer, you can configure the following variables:

### Linux (in CanvusServerInstall.sh)
```bash
ADMIN_EMAIL="admin@local.local"        # Admin user email
ADMIN_PASSWORD_DEFAULT="Taction123!"   # Default admin password
FQDN_DEFAULT=""                        # Your domain name
LETS_ENCRYPT_EMAIL="mt-canvus-server-setup-script@multitaction.com"  # Let's Encrypt contact email
ACTIVATION_KEY_DEFAULT="xxxx-xxxx-xxxx-xxxx"  # Your activation key
```

### Windows Configuration
You can configure the Windows installer in two ways:

**Option 1: Edit the script file** (recommended for repeated use)
```powershell
# Open CanvusServerInstall.ps1 and modify the default values:
param(
    [string]$AdminEmail = "admin@local.local",        # ← Change this
    [string]$AdminPassword = "Taction123!",           # ← Change this  
    [string]$FQDN = "",                               # ← Change this
    [string]$LetsEncryptEmail = "mt-canvus-server-setup-script@multitaction.com",
    [string]$ActivationKey = "xxxx-xxxx-xxxx-xxxx",   # ← Change this
    [switch]$SkipSSL,
    [switch]$Force,
    [string]$DownloadUrl = "https://multitaction687-my.sharepoint.com/:u:/g/personal/jaypaul_barrow_multitaction_com/EX0t--pR6-pHvs9VtgXtJSYBe8pb9esECl-n96EaeFILJg?e=pFi9cL"  # ← Official URL
)
```

**Option 2: Use command line parameters**
```powershell
.\CanvusServerInstall.ps1
    [-AdminEmail <string>]           # Admin user email
    [-AdminPassword <string>]        # Admin password
    [-FQDN <string>]                 # Domain name for SSL certificates
    [-LetsEncryptEmail <string>]     # Let's Encrypt contact email
    [-ActivationKey <string>]        # MT Canvus Server activation key
    [-SkipSSL]                       # Skip SSL certificate setup
    [-Force]                         # Force reinstallation
    [-DownloadUrl <string>]          # Download URL for Windows installer
    [-CustomCertPath <string>]       # Path to existing certificate file
    [-CustomKeyPath <string>]        # Path to existing private key file
    [-CustomChainPath <string>]      # Path to existing certificate chain file
```

## Installation Process

Both installers perform the same core steps:

1. **Package Management**
   - Linux: Updates apt packages, installs dependencies
   - Windows: Installs Chocolatey, PostgreSQL, Git

2. **MT Canvus Server Installation**
   - Linux: Adds MultiTaction repository, installs via apt
   - Windows: Downloads and extracts from MultiTaction servers

3. **Database Configuration**
   - Both: Configures PostgreSQL for MT Canvus Server

4. **Service Installation**
   - Linux: Uses systemd services
   - Windows: Creates Windows Services

5. **Admin User Setup**
   - Both: Creates default admin user account

6. **Software Activation**
   - Both: Applies MT Canvus Server activation key

7. **SSL Certificate Management**
   - Both: Installs Certbot, obtains Let's Encrypt certificates
   - Both: Configures certificate permissions and server settings

8. **Service Verification**
   - Both: Verifies all services are running

## SSL Certificate Management

The installers support two SSL certificate options:

### Option 1: Let's Encrypt (Automatic)
The installers automatically:
- Obtain SSL certificates from Let's Encrypt
- Configure proper permissions
- Set up automatic renewal
- Verify certificate access

### Option 2: Custom Certificates
If you already have SSL certificates, you can use them instead:

**Linux**: Edit the script and set:
```bash
CUSTOM_CERT_PATH="/path/to/your/certificate.pem"
CUSTOM_KEY_PATH="/path/to/your/private-key.pem"
CUSTOM_CHAIN_PATH="/path/to/your/chain.pem"  # Optional
```

**Windows**: Edit the script or use parameters:
```powershell
param(
    [string]$CustomCertPath = "C:\path\to\certificate.pem",
    [string]$CustomKeyPath = "C:\path\to\private-key.pem",
    [string]$CustomChainPath = "C:\path\to\chain.pem"
)
```

**Behavior**:
- If custom certificates are provided: Use them and skip Let's Encrypt
- If no custom certificates: Proceed with Let's Encrypt (if FQDN provided)
- If SkipSSL is used: Skip SSL setup entirely

## Service Management

### Linux
```bash
# Check service status
systemctl status mt-canvus-server mt-canvus-dashboard

# Start services
systemctl start mt-canvus-server mt-canvus-dashboard

# Stop services
systemctl stop mt-canvus-server mt-canvus-dashboard
```

### Windows
```powershell
# Check service status
Get-Service mt-canvus-server, mt-canvus-dashboard

# Start services
Start-Service mt-canvus-server, mt-canvus-dashboard

# Stop services
Stop-Service mt-canvus-server, mt-canvus-dashboard
```

## Error Handling

Both scripts include comprehensive error handling:
- Step-by-step verification
- Automatic recovery attempts
- Detailed error messages
- Safe rerun capability

## Git Sync

To keep your installation up to date, use the following git sync script:

### Linux
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

### Windows
```powershell
# Configuration
$InstallDir = "C:\Program Files\MultiTaction\mt-canvus-server"
$BackupDir = "C:\Backups\Canvus"
$Branch = "main"

# Create backup
Write-Host "Creating backup..."
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = Join-Path $BackupDir "canvus_backup_$timestamp"
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

# Backup critical files
Copy-Item -Path (Join-Path $InstallDir "certs") -Destination $backupPath -Recurse -Force
Copy-Item -Path (Join-Path $InstallDir "mt-canvus-server.ini") -Destination $backupPath -Force

# Pull latest changes
Write-Host "Pulling latest changes..."
Set-Location $InstallDir
git fetch origin
git checkout $Branch
git pull origin $Branch

# Restore backup if needed
if (Test-Path $backupPath) {
    Write-Host "Restoring backup..."
    Copy-Item -Path (Join-Path $backupPath "certs") -Destination $InstallDir -Recurse -Force
    Copy-Item -Path (Join-Path $backupPath "mt-canvus-server.ini") -Destination $InstallDir -Force
}

# Run installer
Write-Host "Running installer..."
.\CanvusServerInstall.ps1

Write-Host "Sync completed. Please check the logs for any warnings or errors."
```

## Troubleshooting

### Linux Issues
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

### Windows Issues
1. Services fail to start:
   - Check PostgreSQL service is running
   - Verify configuration file permissions
   - Review service logs

2. SSL certificate issues:
   - Verify domain DNS settings point to server IP
   - Check certificate file permissions
   - Ensure ports 80 and 443 are accessible

3. Permission issues:
   - Ensure script is run as Administrator
   - Check file and folder permissions
   - Verify service account permissions

## Documentation

- **Linux Installation**: See inline comments in `CanvusServerInstall.sh`
- **Windows Installation**: See `README-Windows.md` for detailed Windows-specific documentation
- **Configuration**: See `config-template.ini` for configuration file structure

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

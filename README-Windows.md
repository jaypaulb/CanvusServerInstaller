# MT Canvus Server Windows Installer

**⚠️ TESTING NOTICE: This Windows installer is currently under testing. Please use in staging environments first and report any issues before production deployment.**

A comprehensive PowerShell installation script for setting up MT Canvus Server on Windows 11, Server 2016, and Server 2022 with automatic SSL certificate handling and service management.

## Features

- Automated installation of MT Canvus Server on Windows
- Automatic SSL certificate management with Let's Encrypt
- Windows Service installation and configuration
- PostgreSQL database setup and configuration
- Idempotent operations (safe to run multiple times)
- Comprehensive error handling and recovery
- Service status verification
- Chocolatey package management integration

## Prerequisites

- Windows 11, Server 2016, or Server 2022
- Administrative privileges
- PowerShell 5.1 or later
- Internet connectivity for package downloads
- **MT Canvus Server Windows installer** (automatically downloaded from official source)
- Public domain name (for SSL certificates)
- Port 443 available (for SSL)
- Port 80 available (for Let's Encrypt verification)

## Windows Installer Download

The installer now includes the official MT Canvus Server Windows installer download URL by default. The script will automatically download the installer from the official MultiTaction SharePoint location.

**Note**: If you need a different version or have issues with the default URL, you can still specify a custom DownloadUrl parameter.

## SkipSSL Option

The `-SkipSSL` parameter allows you to skip SSL certificate setup entirely. Use this option when:

- **Development/Testing**: You're setting up in a development environment
- **Internal Network**: The server will only be accessed internally (no external access)
- **Manual SSL Setup**: You plan to configure SSL certificates manually later
- **HTTP Only**: You want to use HTTP instead of HTTPS

**Security Note**: Using HTTP instead of HTTPS means data will be transmitted in plain text. Only use this option in trusted internal networks or development environments.

## Custom SSL Certificates

If you already have SSL certificates (from your own CA, purchased certificates, etc.), you can use them instead of Let's Encrypt:

### Using Custom Certificates

1. **Edit the script file** (recommended):
   ```powershell
   param(
       [string]$CustomCertPath = "C:\path\to\your\certificate.pem",    # ← Your certificate
       [string]$CustomKeyPath = "C:\path\to\your\private-key.pem",     # ← Your private key
       [string]$CustomChainPath = "C:\path\to\your\chain.pem"          # ← Your chain (optional)
   )
   ```

2. **Or use command line parameters**:
   ```powershell
   .\CanvusServerInstall.ps1 -CustomCertPath "C:\certs\cert.pem" -CustomKeyPath "C:\certs\key.pem"
   ```

### Certificate Requirements

- **Certificate file**: Full certificate chain in PEM format
- **Private key file**: Private key in PEM format
- **Chain file**: Intermediate certificates in PEM format (optional)

### Behavior

- **If custom certificates are provided**: The installer will copy them to the MT Canvus Server location and configure SSL
- **If no custom certificates**: The installer will proceed with Let's Encrypt (if FQDN is provided)
- **If SkipSSL is used**: SSL setup is skipped entirely

## Quick Start

1. **Download the installer:**
   ```powershell
   # Clone or download the repository
   git clone https://github.com/yourusername/CanvusServerInstaller.git
   cd CanvusServerInstaller
   ```

2. **Run the installer:**
   ```powershell
   # Basic installation
   .\CanvusServerInstall.ps1
   
   # With custom parameters
   .\CanvusServerInstall.ps1 -AdminEmail "admin@example.com" -FQDN "canvus.example.com"
   ```

## Configuration Options

You can configure the installer in two ways:

### Option 1: Edit the Script File (Recommended for repeated use)
Open `CanvusServerInstall.ps1` and modify the default values in the `param()` section:

```powershell
param(
    [Parameter(Mandatory = $false)]
    [string]$AdminEmail = "admin@local.local",        # ← Change this
    [string]$AdminPassword = "Taction123!",           # ← Change this
    [string]$FQDN = "",                               # ← Change this
    [string]$LetsEncryptEmail = "mt-canvus-server-setup-script@multitaction.com",
    [string]$ActivationKey = "xxxx-xxxx-xxxx-xxxx",   # ← Change this
    [switch]$SkipSSL,
    [switch]$Force,
    [string]$DownloadUrl = "https://update.multitouch.fi/windows/mt-canvus-server-latest.zip"  # ← Change this
)
```

### Option 2: Use Command Line Parameters
```powershell
.\CanvusServerInstall.ps1
    [-AdminEmail <string>]           # Admin user email (default: admin@local.local)
    [-AdminPassword <string>]        # Admin password (default: Taction123!)
    [-FQDN <string>]                 # Domain name for SSL certificates
    [-LetsEncryptEmail <string>]     # Let's Encrypt contact email
    [-ActivationKey <string>]        # MT Canvus Server activation key
    [-SkipSSL]                       # Skip SSL certificate setup
    [-Force]                         # Force reinstallation
    [-DownloadUrl <string>]          # Download URL for MT Canvus Server Windows installer
    [-CustomCertPath <string>]       # Path to existing certificate file
    [-CustomKeyPath <string>]        # Path to existing private key file
    [-CustomChainPath <string>]      # Path to existing certificate chain file (optional)
```

### Examples

```powershell
# Basic installation with default settings
.\CanvusServerInstall.ps1

# Installation with custom admin account
.\CanvusServerInstall.ps1 -AdminEmail "admin@mycompany.com" -AdminPassword "SecurePass123!"

# Installation with SSL certificate
.\CanvusServerInstall.ps1 -FQDN "canvus.mycompany.com" -LetsEncryptEmail "admin@mycompany.com"

# Installation without SSL
.\CanvusServerInstall.ps1 -SkipSSL

# Installation with activation key
.\CanvusServerInstall.ps1 -ActivationKey "ABCD-EFGH-IJKL-MNOP"

# Installation with custom download URL
.\CanvusServerInstall.ps1 -DownloadUrl "https://example.com/mt-canvus-server-windows.zip"

# Installation without SSL (HTTP only)
.\CanvusServerInstall.ps1 -SkipSSL

# Installation with all custom parameters
.\CanvusServerInstall.ps1 -AdminEmail "admin@mycompany.com" -FQDN "canvus.mycompany.com" -SkipSSL

# Installation with custom SSL certificates
.\CanvusServerInstall.ps1 -CustomCertPath "C:\certs\certificate.pem" -CustomKeyPath "C:\certs\private-key.pem"

# Installation with custom SSL certificates and chain
.\CanvusServerInstall.ps1 -CustomCertPath "C:\certs\certificate.pem" -CustomKeyPath "C:\certs\private-key.pem" -CustomChainPath "C:\certs\chain.pem"
```

## Installation Process

The installer performs the following steps:

1. **Package Manager Setup**
   - Installs Chocolatey package manager
   - Installs PostgreSQL database server
   - Installs Git for repository management

2. **MT Canvus Server Installation**
   - Downloads and extracts MT Canvus Server
   - Installs to `C:\Program Files\MultiTaction\mt-canvus-server`

3. **Database Configuration**
   - Configures PostgreSQL for MT Canvus Server
   - Creates necessary database and user accounts

4. **Service Installation**
   - Installs Windows Services for mt-canvus-server and mt-canvus-dashboard
   - Configures automatic startup

5. **Admin User Setup**
   - Creates default admin user account
   - Configures admin credentials

6. **Software Activation**
   - Applies MT Canvus Server activation key
   - Verifies license status

7. **SSL Certificate Management** (if FQDN provided)
   - Installs Certbot for Let's Encrypt certificates
   - Obtains SSL certificates for the specified domain
   - Configures certificate permissions
   - Updates server configuration for SSL

8. **Service Verification**
   - Verifies all services are running
   - Tests SSL certificate access
   - Provides installation summary

## SSL Certificate Management

### Automatic SSL Setup

When you provide an FQDN, the installer automatically:

1. Installs Certbot for Windows
2. Obtains SSL certificates from Let's Encrypt
3. Configures proper file permissions
4. Updates server configuration
5. Sets up certificate renewal

### Manual SSL Setup

If you prefer to use existing certificates:

1. Place your certificate files in `C:\Program Files\MultiTaction\mt-canvus-server\certs\`
2. Name them:
   - `certificate.pem` (full chain certificate)
   - `certificate-key.pem` (private key)
   - `certificate-chain.pem` (intermediate certificate)
3. Update the configuration file manually

## Service Management

### Windows Services

The installer creates two Windows Services:

- **mt-canvus-server**: Main Canvus Server service
- **mt-canvus-dashboard**: Canvus Dashboard service

### Service Commands

```powershell
# Check service status
Get-Service mt-canvus-server, mt-canvus-dashboard

# Start services
Start-Service mt-canvus-server, mt-canvus-dashboard

# Stop services
Stop-Service mt-canvus-server, mt-canvus-dashboard

# Restart services
Restart-Service mt-canvus-server, mt-canvus-dashboard
```

### Service Logs

```powershell
# View application logs
Get-EventLog -LogName Application -Source mt-canvus-server

# View recent logs
Get-EventLog -LogName Application -Source mt-canvus-server -Newest 50
```

## File Structure

After installation, the following structure is created:

```
C:\Program Files\MultiTaction\
├── mt-canvus-server\
│   ├── bin\
│   │   ├── mt-canvus-server.exe
│   │   └── mt-canvus-dashboard.exe
│   ├── certs\
│   │   ├── certificate.pem
│   │   ├── certificate-key.pem
│   │   └── certificate-chain.pem
│   ├── mt-canvus-server.ini
│   └── MultiTaction\
│       └── Licenses\
└── PostgreSQL\
```

## Troubleshooting

### Common Issues

1. **Services fail to start**
   - Check PostgreSQL service is running
   - Verify configuration file permissions
   - Review service logs

2. **SSL certificate issues**
   - Verify domain DNS settings point to server IP
   - Check certificate file permissions
   - Ensure ports 80 and 443 are accessible

3. **Database connection issues**
   - Verify PostgreSQL service is running
   - Check database user permissions
   - Review PostgreSQL logs

4. **Permission issues**
   - Ensure script is run as Administrator
   - Check file and folder permissions
   - Verify service account permissions

### Log Locations

- **Application Logs**: Event Viewer → Windows Logs → Application
- **Service Logs**: Event Viewer → Windows Logs → System
- **PostgreSQL Logs**: `C:\Program Files\PostgreSQL\[version]\data\pg_log\`

### Manual Recovery

If the installer fails, you can:

1. Check the error messages in the console output
2. Review the Windows Event Logs
3. Manually install missing components
4. Re-run the installer (it's idempotent)

## Security Considerations

1. **Change default passwords** after installation
2. **Use strong admin passwords** (minimum 8 characters, 1 number, 1 special character)
3. **Configure firewall rules** to restrict access
4. **Regular security updates** for Windows and PostgreSQL
5. **SSL certificate renewal** (automatic with Let's Encrypt)

## Updates and Maintenance

### Updating MT Canvus Server

1. Download the latest version
2. Stop the services
3. Backup configuration files
4. Replace the installation files
5. Restart the services

### Certificate Renewal

Let's Encrypt certificates auto-renew, but you can manually renew:

```powershell
certbot renew
```

### Backup and Recovery

Regular backups should include:

- Configuration files (`mt-canvus-server.ini`)
- SSL certificates
- PostgreSQL database
- License files

## Support

For issues with the installer:

1. Check the troubleshooting section above
2. Review Windows Event Logs
3. Verify all prerequisites are met
4. Contact support with detailed error messages

## License

This installer is provided as-is for MT Canvus Server deployment. Please refer to the MT Canvus Server license for usage terms. 
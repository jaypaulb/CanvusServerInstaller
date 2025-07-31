# Testing Guide - Windows Installer

## Overview

The Windows PowerShell installer for MT Canvus Server is currently under testing. This document outlines testing procedures and feedback collection.

## Testing Environments

### Required Test Scenarios

1. **Windows 11** (Desktop/Workstation)
2. **Windows Server 2016** (Standard/Datacenter)
3. **Windows Server 2022** (Standard/Datacenter) - **CLI Interface**
4. **Windows Server 2019** (if available)

### Network Configurations

- **Internal Network Only** (no external access)
- **External Network** (with domain and DNS)
- **Firewall Restricted** (limited port access)

### CLI-Only Testing (Windows Server 2022)

For Windows Server 2022 with CLI interface (no GUI), all testing must be done via PowerShell commands:

```powershell
# Start PowerShell as Administrator
powershell

# Navigate to installation directory
cd C:\path\to\CanvusServerInstaller

# Run installer
.\CanvusServerInstall.ps1

# All verification steps use PowerShell commands (see checklist below)
```

## Test Cases

### Basic Installation
- [x] Fresh Windows installation
- [ ] Installation with default parameters
- [ ] Installation with custom admin credentials
- [ ] Installation without SSL (SkipSSL)

### SSL Certificate Testing
- [ ] Let's Encrypt with valid domain
- [ ] Custom certificates (PEM format)
- [ ] Custom certificates with chain file
- [ ] SSL setup with internal domain only

### Service Management
- [ ] Service installation and startup
- [ ] Service restart after configuration changes
- [ ] Service status verification
- [ ] Service log access

### Error Handling
- [ ] Invalid certificate paths
- [ ] Network connectivity issues
- [ ] Permission problems
- [ ] Invalid parameters

### Package Management
- [ ] Chocolatey installation
- [ ] PostgreSQL installation
- [ ] Git installation
- [ ] MT Canvus Server download

## Known Issues to Monitor

1. **SharePoint Download**: The download URL may require authentication
2. **PowerShell Execution Policy**: May need adjustment on some systems
3. **Service Account Permissions**: Certificate access permissions
4. **Network Timeout**: Download timeouts on slow connections

## CLI-Specific Issues

### Windows Server 2022 CLI Interface

1. **Execution Policy Issues**:
   ```powershell
   # Check current execution policy
   Get-ExecutionPolicy
   
   # Set execution policy for current session
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
   ```

2. **No GUI for Web Testing**:
   ```powershell
   # Use PowerShell to test web interface instead of browser
   try {
       $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing
       Write-Host "Web interface accessible: $($response.StatusCode)" -ForegroundColor Green
   } catch {
       Write-Host "Web interface not accessible: $($_.Exception.Message)" -ForegroundColor Red
   }
   ```

3. **Certificate Testing Without Browser**:
   ```powershell
   # Test SSL certificate validity
   $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
   $cert.Import("C:\Program Files\MultiTaction\mt-canvus-server\certs\certificate.pem")
   Write-Host "Certificate valid until: $($cert.NotAfter)" -ForegroundColor Green
   ```

4. **Service Management Commands**:
   ```powershell
   # Start services manually if needed
   Start-Service mt-canvus-server, mt-canvus-dashboard
   
   # Check service dependencies
   Get-Service mt-canvus-server -DependentServices
   ```

## Feedback Collection

### What to Report

1. **Environment Details**:
   - Windows version and edition
   - PowerShell version
   - Network configuration
   - Antivirus/firewall status

2. **Error Messages**:
   - Full error output
   - Step where error occurred
   - Any manual steps taken

3. **Success Cases**:
   - Working configurations
   - Performance observations
   - User experience feedback

### How to Report

1. **GitHub Issues**: Create detailed issue reports
2. **Email**: Send to development team
3. **Internal Documentation**: Update team knowledge base

## Testing Checklist

### Pre-Test Setup
- [ ] Clean Windows environment
  ```powershell
  # Check Windows version
  Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion
  
  # Check PowerShell version
  $PSVersionTable.PSVersion
  ```
- [ ] Network connectivity verified
  ```powershell
  # Test internet connectivity
  Test-NetConnection -ComputerName 8.8.8.8 -Port 53
  Test-NetConnection -ComputerName google.com -Port 80
  
  # Test SharePoint access (if needed)
  Invoke-WebRequest -Uri "https://multitaction687-my.sharepoint.com" -UseBasicParsing
  ```
- [ ] Administrative privileges confirmed
  ```powershell
  # Check if running as administrator
  ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
  ```
- [ ] PowerShell 5.1+ installed
  ```powershell
  # Check PowerShell version
  $PSVersionTable.PSVersion
  
  # Should be 5.1 or higher
  if ($PSVersionTable.PSVersion.Major -lt 5) {
      Write-Host "PowerShell 5.1+ required" -ForegroundColor Red
  }
  ```

### Installation Test
- [ ] Script runs without errors
  ```powershell
  # Run the installer and check for errors
  .\CanvusServerInstall.ps1
  # Look for any red error messages in output
  ```
- [ ] All services start successfully
  ```powershell
  # Check service status
  Get-Service mt-canvus-server, mt-canvus-dashboard
  
  # Expected output should show "Running" status
  # If not running, check with:
  Get-Service mt-canvus-server, mt-canvus-dashboard | Select-Object Name, Status, StartType
  ```
- [ ] SSL certificates work (if applicable)
  ```powershell
  # Check certificate files exist
  Test-Path "C:\Program Files\MultiTaction\mt-canvus-server\certs\certificate.pem"
  Test-Path "C:\Program Files\MultiTaction\mt-canvus-server\certs\certificate-key.pem"
  
  # Check certificate permissions
  Get-Acl "C:\Program Files\MultiTaction\mt-canvus-server\certs\certificate.pem"
  ```
- [ ] Web interface accessible
  ```powershell
  # Test local access (replace with your domain if using SSL)
  Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing
  # Or for HTTPS:
  Invoke-WebRequest -Uri "https://localhost:8080" -UseBasicParsing -SkipCertificateCheck
  ```
- [ ] Admin login functional
  ```powershell
  # Check if admin user was created
  $mtCanvusPath = "C:\Program Files\MultiTaction\mt-canvus-server"
  $listUsersScript = Join-Path $mtCanvusPath "bin\mt-canvus-server.exe"
  & $listUsersScript --list-users
  ```

### Post-Test Verification
- [ ] Services running after reboot
  ```powershell
  # Restart the server
  Restart-Computer -Force
  
  # After reboot, check services:
  Get-Service mt-canvus-server, mt-canvus-dashboard
  
  # Check if services start automatically
  Get-Service mt-canvus-server, mt-canvus-dashboard | Select-Object Name, StartType
  ```
- [ ] Logs contain no critical errors
  ```powershell
  # Check Windows Event Logs
  Get-EventLog -LogName Application -Source mt-canvus-server -Newest 20
  
  # Check for any errors
  Get-EventLog -LogName Application -EntryType Error -Newest 50 | Where-Object {$_.Source -like "*mt-canvus*"}
  
  # Check system logs for service issues
  Get-EventLog -LogName System -Newest 20 | Where-Object {$_.Message -like "*mt-canvus*"}
  ```
- [ ] Configuration files correct
  ```powershell
  # Check main configuration file
  Get-Content "C:\Program Files\MultiTaction\mt-canvus-server\mt-canvus-server.ini"
  
  # Check for SSL settings (if applicable)
  Select-String -Path "C:\Program Files\MultiTaction\mt-canvus-server\mt-canvus-server.ini" -Pattern "ssl-enabled"
  Select-String -Path "C:\Program Files\MultiTaction\mt-canvus-server\mt-canvus-server.ini" -Pattern "certificate-file"
  ```
- [ ] Performance acceptable
  ```powershell
  # Check service resource usage
  Get-Process | Where-Object {$_.ProcessName -like "*mt-canvus*"} | Select-Object ProcessName, CPU, WorkingSet, Id
  
  # Check disk space
  Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, Size, FreeSpace
  
  # Check memory usage
  Get-WmiObject -Class Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory
  ```

## Rollback Procedures

If testing fails:

1. **Stop Services**:
   ```powershell
   Stop-Service mt-canvus-server, mt-canvus-dashboard
   ```

2. **Remove Services**:
   ```powershell
   sc.exe delete mt-canvus-server
   sc.exe delete mt-canvus-dashboard
   ```

3. **Clean Installation Directory**:
   ```powershell
   Remove-Item "C:\Program Files\MultiTaction" -Recurse -Force
   ```

4. **Remove PostgreSQL** (if needed):
   ```powershell
   choco uninstall postgresql
   ```

## Success Criteria

The Windows installer is ready for production when:

- [ ] All test scenarios pass consistently
- [ ] No critical errors in various environments
- [ ] Performance meets requirements
- [ ] Documentation is complete and accurate
- [ ] Rollback procedures work reliably 
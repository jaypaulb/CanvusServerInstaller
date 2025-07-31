# Testing Guide - Windows Installer

## Overview

The Windows PowerShell installer for MT Canvus Server is currently under testing. This document outlines testing procedures and feedback collection.

## Testing Environments

### Required Test Scenarios

1. **Windows 11** (Desktop/Workstation)
2. **Windows Server 2016** (Standard/Datacenter)
3. **Windows Server 2022** (Standard/Datacenter)
4. **Windows Server 2019** (if available)

### Network Configurations

- **Internal Network Only** (no external access)
- **External Network** (with domain and DNS)
- **Firewall Restricted** (limited port access)

## Test Cases

### Basic Installation
- [ ] Fresh Windows installation
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
- [ ] Network connectivity verified
- [ ] Administrative privileges confirmed
- [ ] PowerShell 5.1+ installed

### Installation Test
- [ ] Script runs without errors
- [ ] All services start successfully
- [ ] SSL certificates work (if applicable)
- [ ] Web interface accessible
- [ ] Admin login functional

### Post-Test Verification
- [ ] Services running after reboot
- [ ] Logs contain no critical errors
- [ ] Configuration files correct
- [ ] Performance acceptable

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
# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2024-12-19

### Added
- **Windows PowerShell installer** for MT Canvus Server
  - Supports Windows 11, Server 2016, and Server 2022
  - Automatic package management via Chocolatey
  - Windows Service installation and configuration
  - **⚠️ Currently under testing - use with caution in production**
- **Custom SSL certificate support** for both Linux and Windows
  - Use existing certificates instead of Let's Encrypt
  - Support for certificate, private key, and chain files
  - Automatic certificate validation and permissions setup
- **Enhanced configuration options**
  - Parameter-based configuration for Windows
  - File-based configuration for Linux
  - Improved documentation and examples

### Changed
- **Improved SSL certificate management**
  - Smart logic: Custom certs → Let's Encrypt → Skip SSL
  - Better error handling and validation
  - Enhanced permissions management
- **Updated documentation**
  - Cross-platform installation guides
  - Comprehensive troubleshooting sections
  - Clear configuration examples

### Technical Details
- **Windows Installer**: PowerShell 5.1+ with administrative privileges required
- **Package Management**: Chocolatey for Windows, apt for Linux
- **SSL Support**: Let's Encrypt (automatic) or custom certificates
- **Service Management**: Windows Services vs systemd services

### Known Issues
- Windows installer requires testing in various Windows environments
- SharePoint download URL may require authentication in some cases
- Custom certificate validation needs field testing

### Migration Notes
- Existing Linux installations are unaffected
- New Windows installations should be tested in staging environments first
- Custom certificate paths must be absolute paths 
# Commit Message for Main Repository Merge

```
feat(installer): add Windows PowerShell installer with custom SSL support

## Major Changes

### New Features
- Add Windows PowerShell installer for MT Canvus Server
  - Supports Windows 11, Server 2016, and Server 2022
  - Automatic package management via Chocolatey
  - Windows Service installation and configuration
  - ⚠️ Currently under testing - use with caution in production

- Add custom SSL certificate support for both platforms
  - Use existing certificates instead of Let's Encrypt
  - Support for certificate, private key, and chain files
  - Automatic certificate validation and permissions setup

- Enhanced configuration options
  - Parameter-based configuration for Windows
  - File-based configuration for Linux
  - Improved documentation and examples

### Technical Improvements
- Smart SSL logic: Custom certs → Let's Encrypt → Skip SSL
- Better error handling and validation
- Enhanced permissions management
- Cross-platform documentation

### Files Added
- CanvusServerInstall.ps1 (Windows PowerShell installer)
- Install-CanvusServer.bat (Windows batch wrapper)
- README-Windows.md (Windows-specific documentation)
- config-template.ini (Configuration template)
- CHANGELOG.md (Version history)
- TESTING.md (Testing guide)

### Files Modified
- README.md (Updated with cross-platform information)
- CanvusServerInstall.sh (Added custom SSL certificate support)

## Testing Status
⚠️ Windows installer is currently under testing. Please test in staging environments before production deployment.

## Breaking Changes
None - existing Linux installations are unaffected.

## Migration Notes
- New Windows installations should be tested in staging environments first
- Custom certificate paths must be absolute paths
- SharePoint download URL may require authentication in some cases

Closes #[issue-number]
```

## Git Commands for Merge

```bash
# Add all files
git add .

# Commit with conventional commit format
git commit -m "feat(installer): add Windows PowerShell installer with custom SSL support

- Add Windows PowerShell installer for MT Canvus Server (Windows 11, Server 2016/2022)
- Add custom SSL certificate support for both Linux and Windows
- Enhanced configuration options and improved documentation
- ⚠️ Windows installer currently under testing

BREAKING CHANGE: None - existing Linux installations unaffected"

# Push to feature branch
git push origin feature/windows-installer

# Create pull request with detailed description
```

## Pull Request Description

```markdown
# Windows PowerShell Installer for MT Canvus Server

## Overview
This PR adds a comprehensive Windows PowerShell installer for MT Canvus Server, bringing feature parity with the existing Linux installer.

## Key Features
- **Windows Support**: Windows 11, Server 2016, and Server 2022
- **Custom SSL Certificates**: Use existing certificates instead of Let's Encrypt
- **Enhanced Configuration**: Parameter-based and file-based configuration options
- **Service Management**: Windows Services with automatic startup
- **Package Management**: Chocolatey integration for dependencies

## Testing Status
⚠️ **IMPORTANT**: The Windows installer is currently under testing. Please test thoroughly in staging environments before production deployment.

## Files Added
- `CanvusServerInstall.ps1` - Main Windows installer
- `Install-CanvusServer.bat` - Batch wrapper for easier execution
- `README-Windows.md` - Windows-specific documentation
- `config-template.ini` - Configuration template
- `CHANGELOG.md` - Version history
- `TESTING.md` - Testing guide

## Files Modified
- `README.md` - Updated with cross-platform information
- `CanvusServerInstall.sh` - Added custom SSL certificate support

## Testing Checklist
- [ ] Windows 11 installation
- [ ] Windows Server 2016 installation
- [ ] Windows Server 2022 installation
- [ ] SSL certificate handling (Let's Encrypt)
- [ ] Custom SSL certificate handling
- [ ] Service management
- [ ] Error handling

## Known Issues
- SharePoint download URL may require authentication
- PowerShell execution policy may need adjustment
- Service account permissions need validation

## Next Steps
1. Test in various Windows environments
2. Collect feedback from users
3. Address any issues found during testing
4. Remove testing notices when ready for production
``` 
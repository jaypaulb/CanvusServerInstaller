@echo off
REM MT Canvus Server Windows Installer Batch Wrapper
REM This batch file provides an easy way to run the PowerShell installer

echo ========================================
echo MT Canvus Server Windows Installer
echo ========================================
echo.

REM Check if PowerShell is available
powershell -Command "exit" >nul 2>&1
if errorlevel 1 (
    echo Error: PowerShell is not available on this system.
    echo Please install PowerShell 5.1 or later.
    pause
    exit /b 1
)

REM Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo Error: This installer must be run as Administrator.
    echo Please right-click and select "Run as Administrator"
    pause
    exit /b 1
)

echo PowerShell and Administrator privileges verified.
echo.

REM Set execution policy for this session
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force" >nul 2>&1

REM Check if the PowerShell script exists
if not exist "CanvusServerInstall.ps1" (
    echo Error: CanvusServerInstall.ps1 not found in the current directory.
    echo Please ensure you're running this from the correct folder.
    pause
    exit /b 1
)

echo Starting MT Canvus Server installation...
echo.

REM Run the PowerShell installer with all arguments passed through
powershell -File "CanvusServerInstall.ps1" %*

REM Check the exit code
if errorlevel 1 (
    echo.
    echo Installation completed with errors.
    echo Please check the output above for details.
    pause
    exit /b 1
) else (
    echo.
    echo Installation completed successfully!
    echo.
    echo You can now access MT Canvus Server at:
    echo - http://localhost (or your server IP)
    echo - https://your-domain.com (if SSL was configured)
    echo.
    pause
    exit /b 0
) 
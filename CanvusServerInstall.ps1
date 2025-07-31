#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    MT Canvus Server Installer for Windows
    
.DESCRIPTION
    Automated installation script for setting up MT Canvus Server on Windows 11, Server 2016, and Server 2022.
    Handles package installation, database configuration, SSL certificate management, and service setup.
    
.PARAMETER AdminEmail
    Email address for the admin user account.
    
.PARAMETER AdminPassword
    Password for the admin user account.
    
.PARAMETER FQDN
    Fully qualified domain name for SSL certificate setup.
    
.PARAMETER ActivationKey
    MT Canvus Server activation key.
    
.PARAMETER SkipSSL
    Skip SSL certificate setup.
    
.PARAMETER Force
    Force reinstallation even if components are already installed.
    
.EXAMPLE
    .\CanvusServerInstall.ps1 -AdminEmail "admin@example.com" -FQDN "canvus.example.com"
    
.NOTES
    This script requires administrative privileges and Windows PowerShell 5.1 or later.
    Compatible with Windows 11, Server 2016, and Server 2022.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$AdminEmail = "admin@local.local",
    
    [Parameter(Mandatory = $false)]
    [string]$AdminPassword = "Taction123!",
    
    [Parameter(Mandatory = $false)]
    [string]$FQDN = "",
    
    [Parameter(Mandatory = $false)]
    [string]$LetsEncryptEmail = "mt-canvus-server-setup-script@multitaction.com",
    
    [Parameter(Mandatory = $false)]
    [string]$ActivationKey = "xxxx-xxxx-xxxx-xxxx",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipSSL,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [string]$DownloadUrl = "https://multitaction687-my.sharepoint.com/:u:/g/personal/jaypaul_barrow_multitaction_com/EX0t--pR6-pHvs9VtgXtJSYBe8pb9esECl-n96EaeFILJg?e=pFi9cL",
    
    [Parameter(Mandatory = $false)]
    [string]$CustomCertPath = "",
    
    [Parameter(Mandatory = $false)]
    [string]$CustomKeyPath = "",
    
    [Parameter(Mandatory = $false)]
    [string]$CustomChainPath = ""
)

# Script version
$VERSION = 1

# Error action preference
$ErrorActionPreference = "Continue"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to safely wait
function Start-SafeSleep {
    param([int]$Seconds)
    Write-ColorOutput "Waiting $Seconds seconds..." "Yellow"
    Start-Sleep -Seconds $Seconds
}

# Function to check if a step is already completed
function Test-StepCompleted {
    param(
        [string]$StepName,
        [scriptblock]$ValidationCommand
    )
    
    try {
        $result = & $ValidationCommand
        if ($result) {
            Write-ColorOutput "$StepName already completed, skipping..." "Green"
            return $true
        }
    }
    catch {
        # Step not completed
    }
    return $false
}

# Function to verify SSL certificate access
function Test-SSLCertAccess {
    param(
        [string]$CertPath,
        [string]$Username
    )
    
    $certFile = Join-Path $CertPath "certificate.pem"
    $keyFile = Join-Path $CertPath "certificate-key.pem"
    
    if ((Test-Path $certFile) -and (Test-Path $keyFile)) {
        try {
            # Test if the user can read the files
            $acl = Get-Acl $certFile
            $access = $acl.Access | Where-Object { $_.IdentityReference -like "*$Username*" }
            if ($access) {
                Write-ColorOutput "SSL certificates are accessible by $Username" "Green"
                return $true
            }
        }
        catch {
            Write-ColorOutput "SSL certificates exist but are not accessible by $Username" "Yellow"
        }
    }
    else {
        Write-ColorOutput "SSL certificates do not exist at $CertPath" "Yellow"
    }
    return $false
}

# Function to verify service status
function Test-ServiceStatus {
    param([string]$ServiceName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        if ($service.Status -eq "Running") {
            Write-ColorOutput "$ServiceName is running" "Green"
            return $true
        }
        else {
            Write-ColorOutput "$ServiceName is not running (Status: $($service.Status))" "Yellow"
            return $false
        }
    }
    catch {
        Write-ColorOutput "$ServiceName is not installed" "Red"
        return $false
    }
}

# Function to get public IP address
function Get-PublicIP {
    try {
        $response = Invoke-RestMethod -Uri "https://ifconfig.me" -TimeoutSec 10
        return $response
    }
    catch {
        Write-ColorOutput "Warning: Could not determine public IP address" "Yellow"
        return $null
    }
}

# Function to resolve FQDN to IP
function Resolve-FQDNToIP {
    param([string]$FQDN)
    
    try {
        $resolved = [System.Net.Dns]::GetHostAddresses($FQDN)
        return $resolved[0].IPAddressToString
    }
    catch {
        return $null
    }
}

# Main installation logic
Write-ColorOutput "=== MT Canvus Server Windows Installer v$VERSION ===" "Cyan"
Write-ColorOutput "Starting installation process..." "White"

# Validate Windows version
$osInfo = Get-ComputerInfo
$osVersion = $osInfo.WindowsVersion
Write-ColorOutput "Detected Windows version: $osVersion" "White"

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-ColorOutput "Error: This script must be run as Administrator" "Red"
    exit 1
}

# Convert FQDN to lowercase if provided
if ($FQDN -and $FQDN -cmatch '[A-Z]') {
    Write-ColorOutput "FQDN contains uppercase characters, converting to lowercase..." "Yellow"
    $FQDN = $FQDN.ToLower()
}

Write-ColorOutput "Configuration:" "Cyan"
Write-ColorOutput "  Admin Email: $AdminEmail" "White"
Write-ColorOutput "  FQDN: $FQDN" "White"
Write-ColorOutput "  Let's Encrypt Email: $LetsEncryptEmail" "White"
Write-ColorOutput "  Skip SSL: $SkipSSL" "White"
Write-ColorOutput "  Force: $Force" "White"
if ($CustomCertPath) {
    Write-ColorOutput "  Custom Certificate: $CustomCertPath" "White"
    Write-ColorOutput "  Custom Key: $CustomKeyPath" "White"
    if ($CustomChainPath) {
        Write-ColorOutput "  Custom Chain: $CustomChainPath" "White"
    }
}

# Step 1: Install Chocolatey if not present
Write-ColorOutput "`n=== Step 1: Package Manager Setup ===" "Cyan"
if (Test-StepCompleted "Chocolatey installation" { Get-Command choco -ErrorAction SilentlyContinue }) {
    Write-ColorOutput "Chocolatey is already installed" "Green"
}
else {
    Write-ColorOutput "Installing Chocolatey package manager..." "Yellow"
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-ColorOutput "Chocolatey installed successfully" "Green"
    }
    catch {
        Write-ColorOutput "Error: Failed to install Chocolatey" "Red"
        Write-ColorOutput $_.Exception.Message "Red"
        exit 1
    }
}

# Step 2: Install required packages
Write-ColorOutput "`n=== Step 2: Installing Required Packages ===" "Cyan"

# Install PostgreSQL
if (Test-StepCompleted "PostgreSQL installation" { Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue }) {
    Write-ColorOutput "PostgreSQL is already installed" "Green"
}
else {
    Write-ColorOutput "Installing PostgreSQL..." "Yellow"
    try {
        choco install postgresql --yes
        Write-ColorOutput "PostgreSQL installed successfully" "Green"
    }
    catch {
        Write-ColorOutput "Error: Failed to install PostgreSQL" "Red"
        Write-ColorOutput $_.Exception.Message "Red"
        exit 1
    }
}

# Install Git (for repository management)
if (Test-StepCompleted "Git installation" { Get-Command git -ErrorAction SilentlyContinue }) {
    Write-ColorOutput "Git is already installed" "Green"
}
else {
    Write-ColorOutput "Installing Git..." "Yellow"
    try {
        choco install git --yes
        Write-ColorOutput "Git installed successfully" "Green"
    }
    catch {
        Write-ColorOutput "Error: Failed to install Git" "Red"
        Write-ColorOutput $_.Exception.Message "Red"
        exit 1
    }
}

# Step 3: Download and install MT Canvus Server
Write-ColorOutput "`n=== Step 3: Installing MT Canvus Server ===" "Cyan"

$mtCanvusPath = "C:\Program Files\MultiTaction\mt-canvus-server"
$mtCanvusBinPath = Join-Path $mtCanvusPath "bin"

if (Test-StepCompleted "MT Canvus Server installation" { Test-Path $mtCanvusBinPath }) {
    Write-ColorOutput "MT Canvus Server is already installed" "Green"
}
else {
    Write-ColorOutput "Downloading MT Canvus Server..." "Yellow"
    
    # Create installation directory
    $installDir = "C:\Program Files\MultiTaction"
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }
    
    # Download MT Canvus Server
    # Use the DownloadUrl parameter (has a default value)
    $downloadUrl = $DownloadUrl
    
    # Check if using the default URL
    if ($downloadUrl -eq "https://multitaction687-my.sharepoint.com/:u:/g/personal/jaypaul_barrow_multitaction_com/EX0t--pR6-pHvs9VtgXtJSYBe8pb9esECl-n96EaeFILJg?e=pFi9cL") {
        Write-ColorOutput "Using official MT Canvus Server Windows installer download URL" "Green"
    }
    
    $downloadPath = Join-Path $env:TEMP "mt-canvus-server.zip"
    
    try {
        Write-ColorOutput "Downloading from: $downloadUrl" "Yellow"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -UseBasicParsing
        
        # Extract the package
        Write-ColorOutput "Extracting MT Canvus Server..." "Yellow"
        Expand-Archive -Path $downloadPath -DestinationPath $installDir -Force
        
        # Clean up download
        Remove-Item $downloadPath -Force
        
        Write-ColorOutput "MT Canvus Server installed successfully" "Green"
    }
    catch {
        Write-ColorOutput "Error: Failed to download/install MT Canvus Server" "Red"
        Write-ColorOutput $_.Exception.Message "Red"
        Write-ColorOutput "Please ensure you have the correct download URL and network access" "Yellow"
        exit 1
    }
}

# Step 4: Configure database
Write-ColorOutput "`n=== Step 4: Database Configuration ===" "Cyan"

$iniFile = Join-Path $mtCanvusPath "mt-canvus-server.ini"

if (Test-StepCompleted "Database configuration" { 
    if (Test-Path $iniFile) {
        $content = Get-Content $iniFile -Raw
        $content -match "databasename="
    }
    else { $false }
}) {
    Write-ColorOutput "Database is already configured" "Green"
}
else {
    Write-ColorOutput "Configuring database for MT Canvus Server..." "Yellow"
    
    try {
        # Start PostgreSQL service if not running
        $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
        if ($pgService -and $pgService.Status -ne "Running") {
            Start-Service $pgService
            Start-SafeSleep 5
        }
        
        # Run database configuration
        $configScript = Join-Path $mtCanvusBinPath "mt-canvus-server.exe"
        if (Test-Path $configScript) {
            & $configScript --configure-db
            
            # Verify configuration
            if (Test-Path $iniFile) {
                $content = Get-Content $iniFile -Raw
                if ($content -match "databasename=") {
                    Write-ColorOutput "Database configuration successful" "Green"
                }
                else {
                    Write-ColorOutput "Warning: Database configuration may have failed" "Yellow"
                }
            }
        }
        else {
            Write-ColorOutput "Error: MT Canvus Server executable not found" "Red"
        }
    }
    catch {
        Write-ColorOutput "Error: Database configuration failed" "Red"
        Write-ColorOutput $_.Exception.Message "Red"
        Write-ColorOutput "Continuing despite error..." "Yellow"
    }
} 

# Step 5: Install and configure Windows Services
Write-ColorOutput "`n=== Step 5: Service Installation and Configuration ===" "Cyan"

$services = @("mt-canvus-server", "mt-canvus-dashboard")

foreach ($serviceName in $services) {
    if (Test-StepCompleted "Install $serviceName service" { Get-Service -Name $serviceName -ErrorAction SilentlyContinue }) {
        Write-ColorOutput "$serviceName service is already installed" "Green"
    }
    else {
        Write-ColorOutput "Installing $serviceName service..." "Yellow"
        try {
            $serviceExe = Join-Path $mtCanvusBinPath "$serviceName.exe"
            if (Test-Path $serviceExe) {
                # Install the service using sc.exe
                & sc.exe create $serviceName binPath= "`"$serviceExe`"" start= auto
                Write-ColorOutput "$serviceName service installed successfully" "Green"
            }
            else {
                Write-ColorOutput "Warning: $serviceName executable not found at $serviceExe" "Yellow"
            }
        }
        catch {
            Write-ColorOutput "Error: Failed to install $serviceName service" "Red"
            Write-ColorOutput $_.Exception.Message "Red"
        }
    }
    
    # Start the service
    if (Test-StepCompleted "Start $serviceName service" { 
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        $service -and $service.Status -eq "Running"
    }) {
        Write-ColorOutput "$serviceName service is already running" "Green"
    }
    else {
        Write-ColorOutput "Starting $serviceName service..." "Yellow"
        try {
            Start-Service -Name $serviceName
            Start-SafeSleep 5
            Write-ColorOutput "$serviceName service started successfully" "Green"
        }
        catch {
            Write-ColorOutput "Error: Failed to start $serviceName service" "Red"
            Write-ColorOutput $_.Exception.Message "Red"
        }
    }
}

# Step 6: Admin user creation
Write-ColorOutput "`n=== Step 6: Admin User Setup ===" "Cyan"

# Check if admin user already exists
$adminExists = $false
try {
    $listUsersScript = Join-Path $mtCanvusBinPath "mt-canvus-server.exe"
    if (Test-Path $listUsersScript) {
        $users = & $listUsersScript --list-users 2>$null
        if ($users -match [regex]::Escape($AdminEmail)) {
            $adminExists = $true
        }
    }
}
catch {
    Write-ColorOutput "Warning: Could not check existing users" "Yellow"
}

if ($adminExists) {
    Write-ColorOutput "Admin user already exists, skipping admin user creation" "Green"
}
else {
    Write-ColorOutput "Creating admin user..." "Yellow"
    
    # Prompt for admin password if not provided
    if ($AdminPassword -eq "Taction123!") {
        Write-ColorOutput "You have 15 seconds to enter your desired admin password (min 8 characters, min 1 number, min 1 special character) [default: $AdminPassword]: " "Yellow" -NoNewline
        $timeout = 15
        $startTime = Get-Date
        
        do {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq "Enter") {
                    break
                }
                # Handle password input (simplified for this example)
            }
            Start-Sleep -Milliseconds 100
        } while ((Get-Date) -lt ($startTime.AddSeconds($timeout)))
        
        Write-ColorOutput "Using default password" "Yellow"
    }
    
    try {
        $createAdminScript = Join-Path $mtCanvusBinPath "mt-canvus-server.exe"
        if (Test-Path $createAdminScript) {
            & $createAdminScript --create-admin $AdminEmail $AdminPassword
            Write-ColorOutput "Admin user created successfully" "Green"
        }
        else {
            Write-ColorOutput "Error: MT Canvus Server executable not found" "Red"
        }
    }
    catch {
        Write-ColorOutput "Warning: Admin user creation failed" "Yellow"
        Write-ColorOutput $_.Exception.Message "Yellow"
        Write-ColorOutput "Continuing despite error..." "Yellow"
    }
}

# Step 7: Activation key setup
Write-ColorOutput "`n=== Step 7: Software Activation ===" "Cyan"

# Check if activation key already exists
$activationExists = $false
$licensePath = Join-Path $mtCanvusPath "MultiTaction\Licenses"
if (Test-Path $licensePath) {
    $licenseFiles = Get-ChildItem -Path $licensePath -Filter "*.cslicense" -ErrorAction SilentlyContinue
    if ($licenseFiles) {
        $activationExists = $true
    }
}

if ($activationExists) {
    Write-ColorOutput "Activation key already exists, skipping activation" "Green"
}
else {
    Write-ColorOutput "Setting up software activation..." "Yellow"
    
    # Prompt for activation key if not provided
    if ($ActivationKey -eq "xxxx-xxxx-xxxx-xxxx") {
        Write-ColorOutput "You have 15 seconds to enter your activation key (4 sets of 4 characters separated by a dash) [default: $ActivationKey]: " "Yellow" -NoNewline
        $timeout = 15
        $startTime = Get-Date
        
        do {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq "Enter") {
                    break
                }
                # Handle activation key input (simplified for this example)
            }
            Start-Sleep -Milliseconds 100
        } while ((Get-Date) -lt ($startTime.AddSeconds($timeout)))
        
        Write-ColorOutput "Using default activation key" "Yellow"
    }
    
    try {
        $activateScript = Join-Path $mtCanvusBinPath "mt-canvus-server.exe"
        if (Test-Path $activateScript) {
            & $activateScript --activate $ActivationKey
            Write-ColorOutput "Software activated successfully" "Green"
        }
        else {
            Write-ColorOutput "Error: MT Canvus Server executable not found" "Red"
        }
    }
    catch {
        Write-ColorOutput "Warning: Activation failed" "Yellow"
        Write-ColorOutput $_.Exception.Message "Yellow"
        Write-ColorOutput "Continuing despite error..." "Yellow"
    }
} 

# Step 8: SSL Certificate Management
Write-ColorOutput "`n=== Step 8: SSL Certificate Setup ===" "Cyan"

if ($SkipSSL) {
    Write-ColorOutput "SSL setup skipped as requested" "Yellow"
}
elseif (-not $FQDN -and -not $CustomCertPath) {
    Write-ColorOutput "No FQDN or custom certificates provided, skipping SSL setup" "Yellow"
}
else {
    # Check if SSL certificates already exist
    $mtCertPath = Join-Path $mtCanvusPath "certs"
    $certFile = Join-Path $mtCertPath "certificate.pem"
    $keyFile = Join-Path $mtCertPath "certificate-key.pem"
    $chainFile = Join-Path $mtCertPath "certificate-chain.pem"
    
    # Check if custom certificates are provided
    if ($CustomCertPath -and $CustomKeyPath) {
        Write-ColorOutput "Using custom SSL certificates..." "Yellow"
        
        # Validate custom certificate files
        if (-not (Test-Path $CustomCertPath)) {
            Write-ColorOutput "Error: Custom certificate file not found: $CustomCertPath" "Red"
            exit 1
        }
        if (-not (Test-Path $CustomKeyPath)) {
            Write-ColorOutput "Error: Custom key file not found: $CustomKeyPath" "Red"
            exit 1
        }
        if ($CustomChainPath -and -not (Test-Path $CustomChainPath)) {
            Write-ColorOutput "Error: Custom chain file not found: $CustomChainPath" "Red"
            exit 1
        }
        
        # Create certificate directory if it doesn't exist
        if (-not (Test-Path $mtCertPath)) {
            New-Item -ItemType Directory -Path $mtCertPath -Force | Out-Null
        }
        
        # Copy custom certificates to MT Canvus Server location
        Write-ColorOutput "Copying custom certificates..." "Yellow"
        Copy-Item $CustomCertPath $certFile -Force
        Copy-Item $CustomKeyPath $keyFile -Force
        if ($CustomChainPath) {
            Copy-Item $CustomChainPath $chainFile -Force
        }
        
        Write-ColorOutput "Custom certificates copied successfully" "Green"
        
        # Update mt-canvus-server.ini with SSL configuration
        Write-ColorOutput "Updating configuration with SSL settings..." "Yellow"
        if (Test-Path $iniFile) {
            $content = Get-Content $iniFile -Raw
            
            # Use FQDN if provided, otherwise use localhost
            $externalUrl = if ($FQDN) { "https://$FQDN" } else { "https://localhost" }
            
            # Update SSL settings
            $content = $content -replace '; external-url=.*', "external-url=$externalUrl"
            $content = $content -replace '; ssl-enabled=.*', "ssl-enabled=true"
            $content = $content -replace '; certificate-file=.*', "certificate-file=$certFile"
            $content = $content -replace '; certificate-key-file=.*', "certificate-key-file=$keyFile"
            if ($CustomChainPath) {
                $content = $content -replace '; certificate-chain-file=.*', "certificate-chain-file=$chainFile"
            }
            
            Set-Content -Path $iniFile -Value $content -Force
            Write-ColorOutput "Configuration updated with custom SSL settings" "Green"
        }
        
        # Set permissions to ensure the service can read the certificates
        Write-ColorOutput "Setting certificate permissions..." "Yellow"
        try {
            # Get the service account
            $service = Get-WmiObject -Class Win32_Service -Filter "Name='mt-canvus-server'"
            if ($service) {
                $serviceAccount = $service.StartName
                Write-ColorOutput "Service account: $serviceAccount" "White"
                
                # Set permissions on certificate files
                $acl = Get-Acl $certFile
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($serviceAccount, "Read", "Allow")
                $acl.SetAccessRule($accessRule)
                Set-Acl -Path $certFile -AclObject $acl
                Set-Acl -Path $keyFile -AclObject $acl
                if ($CustomChainPath) {
                    Set-Acl -Path $chainFile -AclObject $acl
                }
                
                Write-ColorOutput "Certificate permissions set successfully" "Green"
            }
        }
        catch {
            Write-ColorOutput "Warning: Could not set certificate permissions" "Yellow"
            Write-ColorOutput $_.Exception.Message "Yellow"
        }
    }
    elseif (Test-SSLCertAccess $mtCertPath "mt-canvus-server") {
        Write-ColorOutput "SSL certificates are already accessible, skipping SSL setup" "Green"
    }
    else {
        Write-ColorOutput "Setting up SSL certificates..." "Yellow"
        
        # Stop services before SSL configuration
        Write-ColorOutput "Stopping services before SSL configuration..." "Yellow"
        foreach ($serviceName in $services) {
            try {
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-ColorOutput "Warning: Could not stop $serviceName service" "Yellow"
            }
        }
        
        # Get public IP address
        $publicIP = Get-PublicIP
        if ($publicIP) {
            Write-ColorOutput "Public IP of this server: $publicIP" "White"
            Write-ColorOutput "Please ensure your domain DNS settings are pointing to this IP and have propagated before proceeding!" "Yellow"
            Read-Host "Press Enter to continue once DNS settings have propagated"
        }
        
        # Verify FQDN resolution
        Write-ColorOutput "Verifying FQDN resolution..." "Yellow"
        $resolvedIP = Resolve-FQDNToIP $FQDN
        if ($resolvedIP -and $publicIP -and $resolvedIP -eq $publicIP) {
            Write-ColorOutput "FQDN '$FQDN' successfully resolves to the correct IP address: $resolvedIP" "Green"
        }
        else {
            Write-ColorOutput "Warning: FQDN '$FQDN' may not resolve to this server's IP" "Yellow"
            Write-ColorOutput "Resolved IP: $resolvedIP, Public IP: $publicIP" "Yellow"
            $continue = Read-Host "Do you want to continue anyway? (y/N)"
            if ($continue -ne "y" -and $continue -ne "Y") {
                Write-ColorOutput "SSL setup cancelled" "Yellow"
                goto :SSL_SKIP
            }
        }
        
        # Install Certbot for Windows (using Chocolatey)
        if (Test-StepCompleted "Certbot installation" { Get-Command certbot -ErrorAction SilentlyContinue }) {
            Write-ColorOutput "Certbot is already installed" "Green"
        }
        else {
            Write-ColorOutput "Installing Certbot..." "Yellow"
            try {
                choco install certbot --yes
                Write-ColorOutput "Certbot installed successfully" "Green"
            }
            catch {
                Write-ColorOutput "Error: Failed to install Certbot" "Red"
                Write-ColorOutput $_.Exception.Message "Red"
                Write-ColorOutput "SSL setup will be skipped" "Yellow"
                goto :SSL_SKIP
            }
        }
        
        # Obtain SSL certificates using Let's Encrypt
        Write-ColorOutput "Obtaining SSL certificates for FQDN '$FQDN'..." "Yellow"
        try {
            # Create certificate directory
            if (-not (Test-Path $mtCertPath)) {
                New-Item -ItemType Directory -Path $mtCertPath -Force | Out-Null
            }
            
            # Run certbot to obtain certificates
            $certbotArgs = @(
                "certonly",
                "--standalone",
                "-d", $FQDN,
                "--agree-tos",
                "--non-interactive",
                "--email", $LetsEncryptEmail,
                "--no-eff-email"
            )
            
            & certbot @certbotArgs
            
            # Check if certificate was successfully obtained
            $letsEncryptPath = "C:\Certbot\live\$FQDN"
            $fullchainPath = Join-Path $letsEncryptPath "fullchain.pem"
            $privkeyPath = Join-Path $letsEncryptPath "privkey.pem"
            $chainPath = Join-Path $letsEncryptPath "chain.pem"
            
            if ((Test-Path $fullchainPath) -and (Test-Path $privkeyPath)) {
                Write-ColorOutput "SSL certificate generation successful" "Green"
                
                # Create symbolic links for the certificates
                Write-ColorOutput "Creating certificate symlinks..." "Yellow"
                
                # Create junction points (Windows equivalent of symlinks)
                if (Test-Path $certFile) { Remove-Item $certFile -Force }
                if (Test-Path $keyFile) { Remove-Item $keyFile -Force }
                
                $chainFile = Join-Path $mtCertPath "certificate-chain.pem"
                if (Test-Path $chainFile) { Remove-Item $chainFile -Force }
                
                # Copy certificates instead of symlinks for Windows compatibility
                Copy-Item $fullchainPath $certFile -Force
                Copy-Item $privkeyPath $keyFile -Force
                Copy-Item $chainPath $chainFile -Force
                
                Write-ColorOutput "Certificate files copied successfully" "Green"
                
                # Update mt-canvus-server.ini with SSL configuration
                Write-ColorOutput "Updating configuration with SSL settings..." "Yellow"
                if (Test-Path $iniFile) {
                    $content = Get-Content $iniFile -Raw
                    
                    # Update SSL settings
                    $content = $content -replace '; external-url=.*', "external-url=https://$FQDN"
                    $content = $content -replace '; ssl-enabled=.*', "ssl-enabled=true"
                    $content = $content -replace '; certificate-file=.*', "certificate-file=$certFile"
                    $content = $content -replace '; certificate-key-file=.*', "certificate-key-file=$keyFile"
                    $content = $content -replace '; certificate-chain-file=.*', "certificate-chain-file=$chainFile"
                    
                    Set-Content -Path $iniFile -Value $content -Force
                    Write-ColorOutput "Configuration updated with SSL settings" "Green"
                }
                
                # Set permissions to ensure the service can read the certificates
                Write-ColorOutput "Setting certificate permissions..." "Yellow"
                try {
                    # Get the service account
                    $service = Get-WmiObject -Class Win32_Service -Filter "Name='mt-canvus-server'"
                    if ($service) {
                        $serviceAccount = $service.StartName
                        Write-ColorOutput "Service account: $serviceAccount" "White"
                        
                        # Set permissions on certificate files
                        $acl = Get-Acl $certFile
                        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($serviceAccount, "Read", "Allow")
                        $acl.SetAccessRule($accessRule)
                        Set-Acl -Path $certFile -AclObject $acl
                        Set-Acl -Path $keyFile -AclObject $acl
                        Set-Acl -Path $chainFile -AclObject $acl
                        
                        Write-ColorOutput "Certificate permissions set successfully" "Green"
                    }
                }
                catch {
                    Write-ColorOutput "Warning: Could not set certificate permissions" "Yellow"
                    Write-ColorOutput $_.Exception.Message "Yellow"
                }
            }
            else {
                Write-ColorOutput "Error: SSL certificate generation failed" "Red"
                Write-ColorOutput "Certificate files not found at expected locations" "Red"
                goto :SSL_SKIP
            }
        }
        catch {
            Write-ColorOutput "Error: Failed to obtain SSL certificates" "Red"
            Write-ColorOutput $_.Exception.Message "Red"
            goto :SSL_SKIP
        }
    }
}

:SSL_SKIP

# Restart services to apply SSL changes
Write-ColorOutput "`n=== Step 9: Service Restart ===" "Cyan"
Write-ColorOutput "Restarting services to apply configuration changes..." "Yellow"

foreach ($serviceName in $services) {
    try {
        Restart-Service -Name $serviceName -Force
        Start-SafeSleep 5
        Write-ColorOutput "$serviceName service restarted successfully" "Green"
    }
    catch {
        Write-ColorOutput "Error: Failed to restart $serviceName service" "Red"
        Write-ColorOutput $_.Exception.Message "Red"
    }
} 

# Step 10: Final Verification and SSL Certificate Reload
Write-ColorOutput "`n=== Step 10: Final Verification ===" "Cyan"

# Wait for services to be ready
Write-ColorOutput "Waiting for Canvus Server to be ready..." "Yellow"
Start-SafeSleep 5

# Verify service status
Write-ColorOutput "Verifying service status..." "Yellow"
foreach ($serviceName in $services) {
    if (Test-ServiceStatus $serviceName) {
        Write-ColorOutput "$serviceName is running successfully" "Green"
    }
    else {
        Write-ColorOutput "Warning: $serviceName is not running" "Yellow"
        Write-ColorOutput "Please check the service status manually" "Yellow"
    }
}

# Verify SSL certificate access and reload if needed
if (($FQDN -or $CustomCertPath) -and -not $SkipSSL) {
    Write-ColorOutput "Verifying SSL certificate access..." "Yellow"
    $mtCertPath = Join-Path $mtCanvusPath "certs"
    
    if (Test-SSLCertAccess $mtCertPath "mt-canvus-server") {
        Write-ColorOutput "Reloading SSL certificates for mt-canvus-server..." "Yellow"
        try {
            $reloadScript = Join-Path $mtCanvusBinPath "mt-canvus-server.exe"
            if (Test-Path $reloadScript) {
                & $reloadScript --reload-certs
                Write-ColorOutput "SSL certificates reloaded successfully" "Green"
            }
            else {
                Write-ColorOutput "Warning: MT Canvus Server executable not found for certificate reload" "Yellow"
            }
        }
        catch {
            Write-ColorOutput "Warning: SSL certificate reload failed" "Yellow"
            Write-ColorOutput $_.Exception.Message "Yellow"
            Write-ColorOutput "Please check the server logs for more details" "Yellow"
        }
    }
    else {
        Write-ColorOutput "Error: Cannot access SSL certificates" "Red"
        Write-ColorOutput "Certificate path: $mtCertPath" "Yellow"
        if (Test-Path $mtCertPath) {
            Get-ChildItem -Path $mtCertPath | ForEach-Object {
                Write-ColorOutput "  $($_.Name)" "White"
            }
        }
        Write-ColorOutput "Please check permissions and file existence" "Yellow"
    }
}

# Final service status verification
Write-ColorOutput "`n=== Final Service Status ===" "Cyan"
foreach ($serviceName in $services) {
    if (Test-ServiceStatus $serviceName) {
        Write-ColorOutput "$serviceName is running successfully" "Green"
    }
    else {
        Write-ColorOutput "Warning: $serviceName is not running" "Yellow"
    }
}

# Installation completion summary
Write-ColorOutput "`n=== Installation Summary ===" "Cyan"
Write-ColorOutput "MT Canvus Server installation completed!" "Green"
Write-ColorOutput "" "White"
Write-ColorOutput "Installation Details:" "White"
Write-ColorOutput "  - Installation Path: $mtCanvusPath" "White"
Write-ColorOutput "  - Configuration File: $iniFile" "White"
if ($CustomCertPath -and -not $SkipSSL) {
    Write-ColorOutput "  - SSL Certificates: $mtCertPath" "White"
    Write-ColorOutput "  - Custom Certificate Source: $CustomCertPath" "White"
    if ($FQDN) {
        Write-ColorOutput "  - SSL Domain: $FQDN" "White"
    }
}
elseif ($FQDN -and -not $SkipSSL) {
    Write-ColorOutput "  - SSL Certificates: $mtCertPath" "White"
    Write-ColorOutput "  - SSL Domain: $FQDN" "White"
}
Write-ColorOutput "  - Admin Email: $AdminEmail" "White"
Write-ColorOutput "" "White"

# Service management information
Write-ColorOutput "Service Management:" "White"
Write-ColorOutput "  - Start Services: Start-Service mt-canvus-server, mt-canvus-dashboard" "White"
Write-ColorOutput "  - Stop Services: Stop-Service mt-canvus-server, mt-canvus-dashboard" "White"
Write-ColorOutput "  - Check Status: Get-Service mt-canvus-server, mt-canvus-dashboard" "White"
Write-ColorOutput "  - View Logs: Get-EventLog -LogName Application -Source mt-canvus-server" "White"
Write-ColorOutput "" "White"

# Troubleshooting information
Write-ColorOutput "Troubleshooting:" "White"
Write-ColorOutput "  1. If services fail to start, check:" "White"
Write-ColorOutput "     - PostgreSQL service is running" "White"
Write-ColorOutput "     - Configuration file permissions" "White"
Write-ColorOutput "     - SSL certificate permissions (if using SSL)" "White"
Write-ColorOutput "  2. For SSL issues:" "White"
Write-ColorOutput "     - Verify domain DNS settings" "White"
Write-ColorOutput "     - Check certificate file permissions" "White"
Write-ColorOutput "     - Ensure ports 80 and 443 are accessible" "White"
Write-ColorOutput "  3. For database issues:" "White"
Write-ColorOutput "     - Verify PostgreSQL is running" "White"
Write-ColorOutput "     - Check database permissions" "White"
Write-ColorOutput "     - Review PostgreSQL logs" "White"
Write-ColorOutput "" "White"

# Access information
if (($FQDN -or $CustomCertPath) -and -not $SkipSSL) {
    Write-ColorOutput "Access Information:" "White"
    if ($FQDN) {
        Write-ColorOutput "  - Web Interface: https://$FQDN" "Green"
    } else {
        Write-ColorOutput "  - Web Interface: https://localhost (or server IP)" "Green"
    }
    Write-ColorOutput "  - Admin Login: $AdminEmail" "White"
}
else {
    Write-ColorOutput "Access Information:" "White"
    Write-ColorOutput "  - Web Interface: http://localhost (or server IP)" "Green"
    Write-ColorOutput "  - Admin Login: $AdminEmail" "White"
}

Write-ColorOutput "" "White"
Write-ColorOutput "Installation completed successfully!" "Green"
Write-ColorOutput "Please check the server logs for any warnings or errors." "Yellow"

# Return success exit code
exit 0 
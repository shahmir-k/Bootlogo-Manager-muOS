#!/usr/bin/env pwsh

param(
    [switch]$Upload
)

# Shahmir Khan August 11 2025
# https://github.com/shahmir-k
# https://linkedin.com/in/shahmir-k

# Bootlogo Manager .muxzip Package Creator
# This script creates a proper muOS package structure and zips it

# =============================================================================
# USER CONFIGURATION - Set these variables for SSH upload functionality
# =============================================================================
$DEVICE_IP = "192.168.0.113"  # Change to your device's IP address
$username = "root"            # SSH username (usually 'root' for muOS)
$password = "root"        # SSH password (change to your device's password)
# =============================================================================

$version = "1.0.2"

Write-Host "`nCreating Bootlogo Manager .muxzip package..." -ForegroundColor Green

# Remove previous package if it exists
$packageName = "bootlogo-manager-$version-install.muxzip"
$packageNameZip = "bootlogo-manager-$version-install.zip"
if (Test-Path $packageName) {
    Write-Host "Removing previous package: $packageName" -ForegroundColor Yellow
    Remove-Item $packageName -Force
}
if (Test-Path $packageNameZip) {
    Write-Host "Removing previous package: $packageNameZip" -ForegroundColor Yellow
    Remove-Item $packageNameZip -Force
}

# Create temporary directory structure
$tempDir = "temp-muxzip"
if (Test-Path $tempDir) {
    Write-Host "Removing previous temp directory: $tempDir" -ForegroundColor Yellow
    Remove-Item $tempDir -Recurse -Force
}

Write-Host "Creating package structure..." -ForegroundColor Cyan

# Create directory structure
$dirs = @(
    "$tempDir/opt/muos/default/MUOS/theme/active/glyph/muxapp",
    "$tempDir/mnt/mmc/MUOS/application/Bootlogo Manager"
    #"$tempDir/run/muos/storage/init" # Commented out as it's not needed
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "Created: $dir" -ForegroundColor Gray
}

# Copy application files
Write-Host "Copying application files..." -ForegroundColor Cyan
Copy-Item ".bootlogo/*" "$tempDir/mnt/mmc/MUOS/application/Bootlogo Manager/" -Recurse -Force
Copy-Item "package/mux_launch.sh" "$tempDir/mnt/mmc/MUOS/application/Bootlogo Manager/" -Force

# Copy glyph icon
Write-Host "Copying glyph icon..." -ForegroundColor Cyan
Copy-Item "assets/glyph/bootlogo-manager.png" "$tempDir/opt/muos/default/MUOS/theme/active/glyph/muxapp/bootlogo-manager.png" -Force

# Create post-installation script
Write-Host "Creating post-installation script..." -ForegroundColor Cyan
$updateScript = @"
#!/bin/sh

. /opt/muos/script/var/func.sh

# Set proper permissions for bootlogo-manager
chmod +x /mnt/mmc/MUOS/application/Bootlogo Manager/mux_launch.sh
chmod +x /mnt/mmc/MUOS/application/Bootlogo Manager/bin/love
chmod +x /mnt/mmc/MUOS/application/Bootlogo Manager/bin/libs.aarch64/*

# Set user initialization flag
SET_VAR "global" "settings/advanced/user_init" "1"

# Reboot to complete installation
setsid bash -c '
/opt/muos/script/system/halt.sh reboot
'
"@

$updateScript | Out-File -FilePath "$tempDir/opt/update.sh" -Encoding ASCII

# # Create system initialization script (if needed for bootlogo operations)
# Write-Host "Creating system initialization script..." -ForegroundColor Cyan
# $initScript = @"
# #!/bin/sh
# # Bootlogo Manager initialization script
# # This script runs at system startup

# # Set up any required system configurations for bootlogo management
# # (Currently empty as bootlogo operations don't require system initialization)
# "@

# $initScript | Out-File -FilePath "$tempDir/run/muos/storage/init/bootlogo-manager.sh" -Encoding ASCII

# Create package info
Write-Host "Creating package information..." -ForegroundColor Cyan
$packageInfo = @"
Bootlogo Manager for muOS
Version: $version
Description: A tool to manage custom bootlogo installation and removal on muOS devices
Author: shahmir-k
Installation: Place this .zip file in the ARCHIVE directory and install via muOS Archive Manager
"@

$packageInfo | Out-File -FilePath "$tempDir/PACKAGE_INFO.txt" -Encoding ASCII

# Create the zip file
Write-Host "Creating zip package..." -ForegroundColor Cyan
try {
    Compress-Archive -Path "$tempDir/*" -DestinationPath $packageNameZip -Force
    # Get package size
    $packageSize = (Get-Item $packageNameZip).Length
    
    # Rename the zip file to the muxzip file
    Write-Host "Renaming zip file to muxzip file...`n" -ForegroundColor Cyan
    Rename-Item $packageNameZip $packageName -Force
    
    Write-Host "Package created successfully: $packageName" -ForegroundColor Green
    
    $packageSizeMB = [math]::Round($packageSize / 1MB, 2)
    Write-Host "Package size: $packageSizeMB MB" -ForegroundColor Green
    
}
catch {
    Write-Host "Error creating package: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Display package contents
Write-Host "`nPackage contents:" -ForegroundColor Cyan

# Function to generate tree structure with file sizes
function Get-TreeStructure {
    param(
        [string]$Path,
        [string]$Prefix = "",
        [int]$MaxDepth = 10,
        [int]$CurrentDepth = 0
    )
    
    if ($CurrentDepth -ge $MaxDepth) { return }
    
    $items = Get-ChildItem -Path $Path -Force | Sort-Object Name
    $count = $items.Count
    
    for ($i = 0; $i -lt $count; $i++) {
        $item = $items[$i]
        $isLast = ($i -eq $count - 1)
        
        # Determine connector
        $connector = if ($isLast) { "`-- " } else { "|-- " }
        
        # Display item with size information
        $displayName = $item.Name
        if ($item.PSIsContainer) {
            $displayName += "/"
            $sizeInfo = ""
        }
        else {
            # Format file size
            $size = $item.Length
            if ($size -lt 1KB) {
                $sizeInfo = " ($size B)"
            }
            elseif ($size -lt 1MB) {
                $sizeKB = [math]::Round($size / 1KB, 1)
                $sizeInfo = " ($sizeKB KB)"
            }
            elseif ($size -lt 1GB) {
                $sizeMB = [math]::Round($size / 1MB, 2)
                $sizeInfo = " ($sizeMB MB)"
            }
            else {
                $sizeGB = [math]::Round($size / 1GB, 2)
                $sizeInfo = " ($sizeGB GB)"
            }
        }
        
        Write-Host "$Prefix$connector$displayName$sizeInfo" -ForegroundColor Gray
        
        # Recursively process directories
        if ($item.PSIsContainer) {
            $newPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix|   " }
            Get-TreeStructure -Path $item.FullName -Prefix $newPrefix -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
        }
    }
}

# Generate dynamic tree structure from the created package
$packageRoot = "temp-muxzip"
if (Test-Path $packageRoot) {
    Get-TreeStructure -Path $packageRoot
}
else {
    Write-Host "Package structure not found for tree display" -ForegroundColor Yellow
}

# Clean up temporary directory
Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
Remove-Item $tempDir -Recurse -Force

Write-Host "`nPackage creation complete!" -ForegroundColor Green
Write-Host "Package: $packageName" -ForegroundColor White

# Upload to device if -Upload flag is specified
if ($Upload) {
    Write-Host "`nUploading package to device..." -ForegroundColor Cyan
    
    # Check if scp is available
    try {
        $null = Get-Command scp -ErrorAction Stop
    }
    catch {
        Write-Host "Error: scp command not found. Please install OpenSSH or ensure scp is in your PATH." -ForegroundColor Red
        Write-Host "Manual installation: Copy $packageName to your RG35XXSP's ARCHIVE directory" -ForegroundColor Yellow
        exit 1
    }
    
    # Check if package exists
    if (-not (Test-Path $packageName)) {
        Write-Host "Error: Package file $packageName not found!" -ForegroundColor Red
        exit 1
    }
    
    # Test SSH connection first
    # Write-Host "Testing SSH connection to ${DEVICE_IP}..." -ForegroundColor Yellow
    # try {
    #     # Test basic connectivity without BatchMode (allows password auth)
    #     $sshTest = ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "${username}@${DEVICE_IP}" "echo 'SSH connection successful'" 2>&1
    #     if ($LASTEXITCODE -ne 0) {
    #         Write-Host "SSH connection test failed. Please check your device IP, username, and password." -ForegroundColor Red
    #         Write-Host "Manual installation: Copy $packageName to your RG35XXSP's ARCHIVE directory" -ForegroundColor Yellow
    #         exit 1
    #     }
    #     Write-Host "SSH connection test successful!" -ForegroundColor Green
    # }
    # catch {
    #     Write-Host "SSH connection test failed. Please check your device IP, username, and password." -ForegroundColor Red
    #     Write-Host "Manual installation: Copy $packageName to your RG35XXSP's ARCHIVE directory" -ForegroundColor Yellow
    #     exit 1
    # }
    
    # Upload the package using scp
    Write-Host "Uploading $packageName to ${DEVICE_IP}:/mnt/mmc/ARCHIVE/..." -ForegroundColor Yellow
    try {
        # Use sshpass if available, otherwise prompt for password
        $scpCommand = "scp -o ConnectTimeout=30 '$packageName' '${username}@${DEVICE_IP}:/mnt/mmc/ARCHIVE/'"
        
        Invoke-Expression $scpCommand
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Upload successful!" -ForegroundColor Green
            Write-Host "Package uploaded to: /mnt/mmc/ARCHIVE/$packageName" -ForegroundColor Green
            Write-Host "Install via Archive Manager in the muOS Applications menu" -ForegroundColor White
        }
        else {
            Write-Host "Upload failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            Write-Host "Manual installation: Copy $packageName to your RG35XXSP's ARCHIVE directory" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Upload error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Manual installation: Copy $packageName to your RG35XXSP's ARCHIVE directory" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Installation: Copy this file to your RG35XXSP's ARCHIVE directory" -ForegroundColor White
    Write-Host "Then install via Archive Manager in the muOS Applications menu" -ForegroundColor White
    Write-Host "`nTo upload automatically, run: .\create-archive.ps1 -Upload" -ForegroundColor Cyan
}

Write-Host "`n`n" 
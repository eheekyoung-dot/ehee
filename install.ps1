#!/usr/bin/env pwsh
# Installer for ehee.
#
# Usage:
#   irm https://claude.ai/install.ps1 | iex
#
# Optional environment variables:
#   $env:EHEE_INSTALL_DIR   Directory to install the ehee binary into.
#                            Defaults to "$env:LOCALAPPDATA\ehee\bin".
#   $env:EHEE_VERSION       Release tag to install (e.g. "v1.2.3").
#                            Defaults to the latest release.

$ErrorActionPreference = 'Stop'

$Repo = 'eheekyoung-dot/ehee'
$BinName = 'ehee.exe'

function Get-Architecture {
    switch ($env:PROCESSOR_ARCHITECTURE) {
        'AMD64' { return 'x86_64' }
        'ARM64' { return 'arm64' }
        default { throw "Unsupported architecture: $env:PROCESSOR_ARCHITECTURE" }
    }
}

function Get-ReleaseTag {
    if ($env:EHEE_VERSION) {
        return $env:EHEE_VERSION
    }
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
    return $release.tag_name
}

$installDir = if ($env:EHEE_INSTALL_DIR) { $env:EHEE_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'ehee\bin' }
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

$arch = Get-Architecture
$tag = Get-ReleaseTag
$assetName = "ehee-windows-$arch.zip"
$downloadUrl = "https://github.com/$Repo/releases/download/$tag/$assetName"

Write-Host "Downloading ehee $tag ($arch) ..."
$zipPath = Join-Path ([System.IO.Path]::GetTempPath()) $assetName
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

Write-Host "Installing to $installDir ..."
Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
Remove-Item $zipPath -Force

$binPath = Join-Path $installDir $BinName
if (-not (Test-Path $binPath)) {
    throw "Installation failed: $binPath not found after extraction."
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$installDir", 'User')
    $env:Path = "$env:Path;$installDir"
    Write-Host "Added $installDir to your user PATH. Restart your terminal to pick it up."
}

Write-Host ""
Write-Host "ehee $tag installed successfully!"
Write-Host "Run 'ehee --help' to get started."

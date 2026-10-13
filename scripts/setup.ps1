param([switch]$GenerateKey)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$projectRoot = Split-Path -Parent $PSScriptRoot
$toolDirectory = Join-Path $projectRoot '.tools'
$downloads = Join-Path $toolDirectory 'downloads'
New-Item -ItemType Directory -Path $downloads -Force | Out-Null
$packages = @(
    @{
        Name = 'Connect IQ SDK 9.2.0'
        Url = 'https://developer.garmin.com/downloads/connect-iq/sdks/connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2.zip'
        File = 'connectiq-sdk-9.2.0.zip'
        Hash = '9B0DB34EDBA465CD7D146B513C21EE95E1DF469A07689C81AB09A75666CAB86C'
        Destination = 'connectiq-sdk'
        Marker = 'bin\monkeybrains.jar'
    },
    @{
        Name = 'Temurin JDK 17.0.20.1+1'
        Url = 'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.20.1%2B1/OpenJDK17U-jdk_x64_windows_hotspot_17.0.20.1_1.zip'
        File = 'temurin-jdk17.zip'
        Hash = 'E53A79C3C3D86865BD7E787903884331068E71321714FFD44F145785AFFC7CB0'
        Destination = 'java'
        Marker = 'jdk-17.0.20.1+1\bin\java.exe'
    },
    @{
        Name = 'Connect IQ SDK Manager 1.0.16'
        Url = 'https://developer.garmin.com/downloads/connect-iq/sdk-manager/connectiq-sdk-manager-windows.zip'
        File = 'sdk-manager.zip'
        Hash = '9B92B25CA3DF314A6618DF493D5D3A8854BCE98915F92E98CA749316BC5DC2FB'
        Destination = 'sdk-manager'
        Marker = 'sdkmanager.exe'
    }
)
foreach ($package in $packages) {
    $archive = Join-Path $downloads $package.File
    if (-not (Test-Path -LiteralPath $archive)) {
        Write-Output "Downloading $($package.Name)"
        Invoke-WebRequest -UseBasicParsing -Uri $package.Url -OutFile $archive
    }
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $package.Hash) {
        throw "Checksum mismatch for $($package.Name). Do not execute or extract this archive. SDK Manager's download URL may have changed versions; review its new official release before updating the pinned hash."
    }
    $destination = Join-Path $toolDirectory $package.Destination
    if (-not (Test-Path -LiteralPath (Join-Path $destination $package.Marker))) {
        Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
    }
    Write-Output "$($package.Name): ready (SHA-256 verified)."
}
if ($GenerateKey) {
    $key = Join-Path $projectRoot '.private\developer_key.der'
    if (Test-Path -LiteralPath $key) { Write-Output 'Existing signing key retained.' }
    else {
        $java = Join-Path $toolDirectory 'java\jdk-17.0.20.1+1\bin\java.exe'
        & $java (Join-Path $PSScriptRoot 'GenerateDeveloperKey.java') $key
        if ($LASTEXITCODE -ne 0) { throw 'Signing key generation failed.' }
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        & icacls.exe (Split-Path -Parent $key) /inheritance:r /grant:r "${identity}:(OI)(CI)F" 'SYSTEM:(OI)(CI)F'
        if ($LASTEXITCODE -ne 0) { throw 'Signing key permission setup failed.' }
    }
}
Write-Output 'Toolchain ready. Use SDK Manager to install the four fr255 device definitions and required fonts.'
Write-Output "SDK Manager: $(Join-Path $toolDirectory 'sdk-manager\sdkmanager.exe')"
Write-Output 'Garmin SDK terms: https://developer.garmin.com/downloads/connect-iq/sdks/agreement.html'

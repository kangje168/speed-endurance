param(
    [string]$SdkBin,
    [string]$DeveloperKey,
    [string]$JavaExecutable,
    [ValidateSet('fr255','fr255m','fr255s','fr255sm')][string]$Device = 'fr255',
    [switch]$Tests,
    [switch]$Release
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Toolchain.ps1')
$toolchain = Resolve-PaceToolchain -SdkBin $SdkBin -JavaExecutable $JavaExecutable -DeveloperKey $DeveloperKey
$projectRoot = $toolchain.Root
$outputDirectory = Join-Path $projectRoot 'bin'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$jungle = 'monkey.jungle'
$fileName = "SpeedEndurance-$Device.prg"
if ($Tests) { $jungle = 'tests.jungle'; $fileName = "SpeedEndurance-$Device-tests.prg" }
$outputFile = Join-Path $outputDirectory $fileName
$arguments = @('-f', (Join-Path $projectRoot $jungle), '-d', $Device, '-o', $outputFile, '-y', $toolchain.Key, '-w', '-l', '1', '--build-stats', '0')
if ($Tests) { $arguments += '-t' }
if ($Release) { $arguments += '-r' }
Push-Location $projectRoot
try { & $toolchain.Java -Xms256m -jar $toolchain.Compiler @arguments }
finally { Pop-Location }
if ($LASTEXITCODE -ne 0) { throw "Compilation failed: $LASTEXITCODE" }
Write-Output "Built: $outputFile"
if ($Tests) {
    Write-Output 'Start the Connect IQ simulator, then run:'
    Write-Output "& '$($toolchain.Java)' -cp '$($toolchain.Compiler)' com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux -f '$outputFile' -d '$Device' -s '$($toolchain.SdkBin)\shell.exe' -t"
}

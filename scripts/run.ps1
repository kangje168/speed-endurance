param(
    [ValidateSet('fr255','fr255m','fr255s','fr255sm')][string]$Device = 'fr255',
    [string]$SdkBin, [string]$DeveloperKey, [string]$JavaExecutable,
    [switch]$ShowSimulator
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Toolchain.ps1')
$toolchain = Resolve-PaceToolchain -SdkBin $SdkBin -JavaExecutable $JavaExecutable -DeveloperKey $DeveloperKey
$program = Join-Path $toolchain.Root "bin\SpeedEndurance-$Device.prg"
if (-not (Test-Path -LiteralPath $program)) { throw 'Build the selected device first with scripts/build.ps1.' }
if (-not (Get-Process simulator -ErrorAction SilentlyContinue)) {
    $style = 'Hidden'
    if ($ShowSimulator) { $style = 'Normal' }
    Start-Process -FilePath (Join-Path $toolchain.SdkBin 'simulator.exe') -WorkingDirectory $toolchain.SdkBin -WindowStyle $style | Out-Null
}
& $toolchain.Java -cp $toolchain.Compiler com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux -f $program -d $Device -s (Join-Path $toolchain.SdkBin 'shell.exe')

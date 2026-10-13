param([string]$SdkBin, [string]$DeveloperKey, [string]$JavaExecutable)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Toolchain.ps1')
$toolchain = Resolve-PaceToolchain -SdkBin $SdkBin -JavaExecutable $JavaExecutable -DeveloperKey $DeveloperKey
if (-not (Get-Process simulator -ErrorAction SilentlyContinue)) { throw 'Start the Connect IQ simulator before running the release script.' }
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $toolchain.Root 'release\metadata.json') | ConvertFrom-Json
$releaseDirectory = Join-Path $toolchain.Root 'release'
$logDirectory = Join-Path $releaseDirectory 'build-logs'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$matrix = @()
foreach ($device in @('fr255','fr255m','fr255s','fr255sm')) {
    & (Join-Path $PSScriptRoot 'build.ps1') -SdkBin $toolchain.SdkBin -DeveloperKey $toolchain.Key -JavaExecutable $toolchain.Java -Device $device -Release
    & (Join-Path $PSScriptRoot 'build.ps1') -SdkBin $toolchain.SdkBin -DeveloperKey $toolchain.Key -JavaExecutable $toolchain.Java -Device $device -Tests
    $testFile = Join-Path $toolchain.Root "bin\SpeedEndurance-$device-tests.prg"
    $log = Join-Path $logDirectory "$device-tests.txt"
    & $toolchain.Java -cp $toolchain.Compiler com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux -f $testFile -d $device -s (Join-Path $toolchain.SdkBin 'shell.exe') -t 2>&1 | Tee-Object -FilePath $log
    $runnerExitCode = $LASTEXITCODE
    $testOutput = Get-Content -Raw $log
    # The SDK launcher returned 1 even with an all-pass summary on this Windows setup.
    # Require the native runner's exact zero-failure/zero-error result; retain its exit code.
    if ($runnerExitCode -notin @(0, 1) -or $testOutput -notmatch '(?im)^PASSED\s*\(passed=(\d+), failed=0, errors=0\)' -or $testOutput -match '(?im)^FAILED\s*\(|TEST\s+FAILED|Unhandled Exception') {
        throw "Could not confirm successful native tests on $device. Inspect $log."
    }
    $passCount = [int]([regex]::Match($testOutput, '(?im)^PASSED\s*\(passed=(\d+), failed=0, errors=0\)').Groups[1].Value)
    $expectedTests = (Get-ChildItem (Join-Path $toolchain.Root 'tests') -Filter '*.mc' |
        ForEach-Object { ([regex]::Matches((Get-Content -Raw $_.FullName), '\(:test\)')).Count } |
        Measure-Object -Sum).Sum
    if ($passCount -ne $expectedTests) { throw "Unexpected test count on $device`: passed $passCount, expected $expectedTests." }
    $matrix += [pscustomobject]@{ device = $device; compiled = $true; nativeTests = 'passed'; testsPassed = $passCount; runnerExitCode = $runnerExitCode; log = "$device-tests.txt" }
}
$packageFile = Join-Path $releaseDirectory "SpeedEndurance-$($metadata.version).iq"
Push-Location $toolchain.Root
try {
    & $toolchain.Java -Xms256m -jar $toolchain.Compiler -f (Join-Path $toolchain.Root 'monkey.jungle') -e -r -w -l 1 -o $packageFile -y $toolchain.Key
    if ($LASTEXITCODE -ne 0) { throw 'IQ package export failed.' }
} finally { Pop-Location }
& $toolchain.Java --class-path $toolchain.Compiler (Join-Path $PSScriptRoot 'InspectPackage.java') $packageFile
if ($LASTEXITCODE -ne 0) { throw 'Exported IQ package validation failed.' }
$report = [pscustomobject]@{
    version = $metadata.version
    builtAtUtc = [DateTime]::UtcNow.ToString('o')
    package = (Split-Path -Leaf $packageFile)
    sha256 = (Get-FileHash -LiteralPath $packageFile -Algorithm SHA256).Hash
    archiveValidation = 'Manifest and binaries verified for all four intended devices; no private keys or tool files included.'
    matrix = $matrix
    hardwareValidation = 'Pending: complete release/HARDWARE-TESTS.md before store submission.'
}
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $releaseDirectory 'build-report.json')
Write-Output "Store package: $packageFile"
Write-Output 'Complete hardware validation and review the listing before submitting to Garmin.'

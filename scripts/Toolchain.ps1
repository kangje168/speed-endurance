# Shared toolchain resolution. Dot-source this file from project scripts.
function Resolve-PaceToolchain {
    param([string]$SdkBin, [string]$JavaExecutable, [string]$DeveloperKey)
    $projectRoot = Split-Path -Parent $PSScriptRoot
    if (-not $SdkBin) { $SdkBin = Join-Path $projectRoot '.tools\connectiq-sdk\bin' }
    if (-not $JavaExecutable) {
        $localJava = Join-Path $projectRoot '.tools\java'
        if (Test-Path -LiteralPath $localJava) {
            $JavaExecutable = Get-ChildItem -LiteralPath $localJava -Recurse -Filter java.exe |
                Select-Object -First 1 -ExpandProperty FullName
        }
        if (-not $JavaExecutable) {
            $javaCommand = Get-Command java -ErrorAction SilentlyContinue
            if ($javaCommand) { $JavaExecutable = $javaCommand.Source }
        }
    }
    if (-not $DeveloperKey) { $DeveloperKey = Join-Path $projectRoot '.private\developer_key.der' }
    $compilerJar = Join-Path $SdkBin 'monkeybrains.jar'
    if (-not (Test-Path -LiteralPath $compilerJar)) { throw 'Connect IQ SDK missing. Supply -SdkBin or install it in .tools/connectiq-sdk.' }
    if (-not $JavaExecutable -or -not (Test-Path -LiteralPath $JavaExecutable)) { throw 'Java missing. Supply -JavaExecutable or install it in .tools/java.' }
    if (-not (Test-Path -LiteralPath $DeveloperKey)) { throw 'Signing key missing. Supply -DeveloperKey. Never replace an existing release key.' }
    return [pscustomobject]@{
        Root = $projectRoot
        SdkBin = (Resolve-Path -LiteralPath $SdkBin).Path
        Java = (Resolve-Path -LiteralPath $JavaExecutable).Path
        Compiler = (Resolve-Path -LiteralPath $compilerJar).Path
        Key = (Resolve-Path -LiteralPath $DeveloperKey).Path
    }
}

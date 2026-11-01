[CmdletBinding()]
param(
    [string]$OutputDirectory = "Releases",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$builder = Join-Path $PSScriptRoot "build_mods.py"
if (-not (Test-Path -LiteralPath $builder -PathType Leaf)) {
    throw "Missing build script: $builder"
}

$arguments = @($builder, "--output-dir", $OutputDirectory)
if ($Clean) {
    $arguments += "--clean"
}

Push-Location $repoRoot
try {
    & python @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Mod build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

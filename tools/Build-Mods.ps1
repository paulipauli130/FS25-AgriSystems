[CmdletBinding()]
param(
    [string]$OutputDirectory = "Releases",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$outputRoot = Join-Path $repoRoot $OutputDirectory
$stagingRoot = Join-Path $outputRoot ".staging"

$mods = @(
    @{ Name = "Spray_Hygiene"; Package = "FS25_AgriSystems_SprayHygiene.zip" },
    @{ Name = "Farm_Biosecurity"; Package = "FS25_AgriSystems_FarmBiosecurity.zip" }
)

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
if ($Clean -and (Test-Path $stagingRoot)) {
    Remove-Item $stagingRoot -Recurse -Force
}

foreach ($mod in $mods) {
    $sourceRoot = Join-Path $repoRoot $mod.Name
    $stage = Join-Path $stagingRoot $mod.Name
    $modDescPath = Join-Path $sourceRoot "modDesc.xml"

    if (-not (Test-Path $modDescPath -PathType Leaf)) {
        throw "Missing modDesc.xml: $modDescPath"
    }

    if (Test-Path $stage) {
        Remove-Item $stage -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stage -Force | Out-Null

    [xml]$descriptor = Get-Content -LiteralPath $modDescPath -Raw
    if ($descriptor.modDesc -eq $null) {
        throw "Invalid modDesc.xml root in $modDescPath"
    }

    foreach ($sourceFile in $descriptor.modDesc.extraSourceFiles.sourceFile) {
        $relativePath = [string]$sourceFile.filename
        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            throw "Empty sourceFile entry in $modDescPath"
        }
        $candidate = Join-Path $sourceRoot $relativePath
        if (-not (Test-Path $candidate -PathType Leaf)) {
            throw "modDesc references missing source file: $candidate"
        }
    }

    Copy-Item -LiteralPath $modDescPath -Destination $stage
    foreach ($runtimeDirectory in @("scripts", "translations", "config", "assets", "store")) {
        $candidate = Join-Path $sourceRoot $runtimeDirectory
        if (Test-Path $candidate -PathType Container) {
            Copy-Item -LiteralPath $candidate -Destination $stage -Recurse
        }
    }

    $archivePath = Join-Path $outputRoot $mod.Package
    if (Test-Path $archivePath) {
        Remove-Item $archivePath -Force
    }

    Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $archivePath -CompressionLevel Optimal
    Write-Host ("Built {0} (mod version {1})" -f $archivePath, $descriptor.modDesc.version)
}

Write-Host "Build finished. Documentation, tests and repository metadata were excluded."

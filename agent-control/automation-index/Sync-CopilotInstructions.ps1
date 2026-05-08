[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$sourceFile = Join-Path $workspaceRoot '.github\copilot-instructions.md'

if (-not (Test-Path -Path $sourceFile -PathType Leaf)) {
    throw "Source file not found: $sourceFile"
}

$targetRepos = @(
    'dcc-pricing-supply',
    'csl-pricing-supply',
    'pdi-clone-core',
    'citysv-prices',
    'citysv-costs',
    'gravitate-orders'
)

$results = New-Object System.Collections.Generic.List[object]

foreach ($repo in $targetRepos) {
    $targetDir = Join-Path $workspaceRoot $repo
    $targetFile = Join-Path $targetDir '.github\copilot-instructions.md'
    $claudeFile = Join-Path $targetDir 'CLAUDE.md'

    if (-not (Test-Path -Path $targetDir -PathType Container)) {
        $results.Add([pscustomobject]@{
            Repo = $repo
            Status = 'SKIPPED'
            Detail = 'Repo folder not found'
            Target = $targetFile
        })
        continue
    }

    if ($DryRun) {
        $results.Add([pscustomobject]@{
            Repo = $repo
            Status = 'WOULD_SYNC'
            Detail = 'Dry run only'
            Target = "$targetFile ; $claudeFile"
        })
        continue
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $targetFile) | Out-Null
    Copy-Item -Path $sourceFile -Destination $targetFile -Force
    Copy-Item -Path $sourceFile -Destination $claudeFile -Force

    $results.Add([pscustomobject]@{
        Repo = $repo
        Status = 'SYNCED'
        Detail = 'Updated copilot-instructions and CLAUDE.md from canonical source'
        Target = "$targetFile ; $claudeFile"
    })
}

$results | Format-Table -AutoSize | Out-String

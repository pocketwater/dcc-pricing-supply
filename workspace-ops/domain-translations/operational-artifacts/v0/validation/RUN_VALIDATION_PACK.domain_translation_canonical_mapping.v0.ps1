param(
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [string]$Database = 'PDI_PricingLink',

    [Parameter(Mandatory = $false)]
    [string]$CloneDbName = 'PDI_Clone_DB',

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = '.\\validation-evidence',

    [Parameter(Mandatory = $false)]
    [string]$ParityTable = ''
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sqlPath = Join-Path $scriptDir 'VALIDATION_EXECUTION_PACK.domain_translation_canonical_mapping.v0.sql'

if (-not (Test-Path $sqlPath)) {
    throw "SQL pack not found: $sqlPath"
}

if (-not (Test-Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outFile = Join-Path $OutputFolder ("validation_pack_output_" + $timestamp + ".txt")
$resolvedSqlFile = Join-Path $OutputFolder ("validation_pack_resolved_" + $timestamp + ".sql")

$sql = Get-Content $sqlPath -Raw
$sql = $sql.Replace('{{PDI_CLONE_DB}}', $CloneDbName)
if ($ParityTable -ne '') {
    $sql = $sql.Replace('{{CITT_TABLE_PRODUCT_GRAVITATE_TO_PDI}}', $ParityTable)
}

Set-Content -Path $resolvedSqlFile -Value $sql

"Run timestamp: $(Get-Date -Format o)" | Tee-Object -FilePath $outFile
"Server: $ServerInstance" | Tee-Object -FilePath $outFile -Append
"Database: $Database" | Tee-Object -FilePath $outFile -Append
"Clone DB: $CloneDbName" | Tee-Object -FilePath $outFile -Append
"Resolved SQL: $resolvedSqlFile" | Tee-Object -FilePath $outFile -Append
"" | Tee-Object -FilePath $outFile -Append

$result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $sql -QueryTimeout 0
$result | Format-Table -AutoSize | Out-String | Tee-Object -FilePath $outFile -Append

"" | Tee-Object -FilePath $outFile -Append
"Validation run complete." | Tee-Object -FilePath $outFile -Append
"Evidence file: $outFile" | Tee-Object -FilePath $outFile -Append

Write-Output "Validation pack executed successfully."
Write-Output "Evidence file: $outFile"
Write-Output "Resolved SQL file: $resolvedSqlFile"

param(
    [Parameter(Mandatory = $false)]
    [string]$ServerInstance = 'PDI-SQL-02',

    [Parameter(Mandatory = $false)]
    [string]$Database = 'PDI_PricingLink',

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = '.\\evidence'
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sqlPath = Join-Path $scriptDir 'FUNCTIONAL_TEST_BOOTSTRAP_SQL02.domain_translation_canonical_mapping.v0.sql'

if (-not (Test-Path $sqlPath)) {
    throw "SQL file not found: $sqlPath"
}

if (-not (Test-Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory | Out-Null
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outPath = Join-Path $OutputFolder ("functional_test_sql02_" + $stamp + ".txt")

"Run timestamp: $(Get-Date -Format o)" | Tee-Object -FilePath $outPath
"Server: $ServerInstance" | Tee-Object -FilePath $outPath -Append
"Database: $Database" | Tee-Object -FilePath $outPath -Append
"SQL: $sqlPath" | Tee-Object -FilePath $outPath -Append
"" | Tee-Object -FilePath $outPath -Append

$sql = Get-Content $sqlPath -Raw
$result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -TrustServerCertificate -Query $sql -QueryTimeout 0
$result | Format-Table -AutoSize | Out-String | Tee-Object -FilePath $outPath -Append

"" | Tee-Object -FilePath $outPath -Append
"Functional test complete." | Tee-Object -FilePath $outPath -Append
"Evidence file: $outPath" | Tee-Object -FilePath $outPath -Append

Write-Output "Functional test completed successfully."
Write-Output "Evidence file: $outPath"

param(
    [string]$BaseUrl = $env:GRAV_BASE_URL,
    [string]$ClientId = $env:GRAV_CLIENT_ID,
    [string]$ClientSecret = $env:GRAV_CLIENT_SECRET,
    [string]$Scope = $(if ($env:GRAV_SCOPE) { $env:GRAV_SCOPE } else { "bbd" }),
    [int]$TimeoutSec = $(if ($env:GRAV_TIMEOUT_SECONDS) { [int]$env:GRAV_TIMEOUT_SECONDS } else { 60 })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-TrailingSlash([string]$url) {
    if ([string]::IsNullOrWhiteSpace($url)) { return $url }
    if ($url.EndsWith("/")) { return $url }
    return "$url/"
}

if ([string]::IsNullOrWhiteSpace($BaseUrl) -or [string]::IsNullOrWhiteSpace($ClientId) -or [string]::IsNullOrWhiteSpace($ClientSecret)) {
    throw "Missing required inputs. Set GRAV_BASE_URL, GRAV_CLIENT_ID, GRAV_CLIENT_SECRET (or pass params)."
}

$base = Ensure-TrailingSlash $BaseUrl
$tokenUrl = "$base" + "token"

Write-Host "[1/4] Requesting token from $tokenUrl"
$tokenResp = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body @{
    client_id = $ClientId
    client_secret = $ClientSecret
    scope = $Scope
} -TimeoutSec $TimeoutSec

if (-not $tokenResp.access_token) {
    throw "No access_token returned by token endpoint."
}

$headers = @{ Authorization = "Bearer $($tokenResp.access_token)" }

$tests = @(
    @{ Name = "Locations"; Path = "v1/location/all"; Body = @{} },
    @{ Name = "Counterparties"; Path = "v1/counterparty/all"; Body = @{} },
    @{ Name = "Trailers"; Path = "v1/trailer/all"; Body = @{} }
)

$results = @()
$index = 2
foreach ($test in $tests) {
    $url = "$base$($test.Path)"
    Write-Host "[$index/4] Calling $($test.Name): $url"
    try {
        $resp = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body ($test.Body | ConvertTo-Json -Depth 8) -ContentType "application/json" -TimeoutSec $TimeoutSec
        $count = if ($resp -is [System.Collections.IEnumerable] -and $resp -isnot [string]) { @($resp).Count } else { 1 }
        $results += [pscustomobject]@{ endpoint = $test.Path; status = "OK"; records = $count; error = $null }
    }
    catch {
        $results += [pscustomobject]@{ endpoint = $test.Path; status = "ERROR"; records = $null; error = $_.Exception.Message }
    }
    $index++
}

Write-Host "`nConnectivity summary:"
$results | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.status -ne "OK" }).Count
if ($failed -gt 0) {
    exit 1
}

exit 0

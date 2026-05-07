# Tenant confirmed: coleman -> https://coleman.bb.gravitate.energy/api/
# This script is archived for reference only.
$clientId = "acf14797ea0a13b9360c10300b06488d6d279d7cb8d7d1ba"
$clientSecret = "1c583ee28652e96213f732defa2c994df7f12af797f79d4845c3c1522d055060"
$candidates = @("coleman","colemancoil","colemanoil","citysv","cityservice","cityservicevalcon")

foreach ($slug in $candidates) {
    $url = "https://$slug.bb.gravitate.energy/api/token"
    try {
        $resp = Invoke-RestMethod -Method Post -Uri $url -Body @{
            client_id = $clientId
            client_secret = $clientSecret
            scope = "bbd"
        } -TimeoutSec 10 -ErrorAction Stop
        if ($resp.access_token) {
            Write-Host "HIT: $slug -> $url" -ForegroundColor Green
            Write-Host "TOKEN_PREFIX=$($resp.access_token.Substring(0,20))..."
        }
    } catch {
        $statusCode = $null
        if ($_.Exception.Response) { $statusCode = [int]$_.Exception.Response.StatusCode }
        Write-Host ("MISS: {0} (status={1})" -f $slug, $statusCode) -ForegroundColor DarkGray
    }
}

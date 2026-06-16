# Sprint 02 acceptance verification for EARP API gateway.
param()

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

if (-not (Test-Path ".env")) {
    Write-Host "Creating .env from .env.example"
    Copy-Item ".env.example" ".env"
} elseif (-not (Select-String -Path ".env" -Pattern '^\s*JWT_SECRET=' -Quiet)) {
    Write-Host "Appending Sprint 02 variables to .env"
    @"

# Sprint 02 — FastAPI API Gateway
ENVIRONMENT=development
JWT_SECRET=change-me-in-local-env
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=60
API_GATEWAY_PORT=8000
POSTGRES_HOST=postgres
VALKEY_HOST=valkey
"@ | Add-Content ".env"
}

Get-Content ".env" | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
    }
}

$ApiPort = if ($env:API_GATEWAY_PORT) { $env:API_GATEWAY_PORT } else { "8000" }
$BaseUrl = "http://localhost:$ApiPort"

function Pass([string]$Message) { Write-Host "[PASS] $Message" -ForegroundColor Green }
function Fail([string]$Message) { Write-Host "[FAIL] $Message" -ForegroundColor Red; exit 1 }

function Get-ContainerHealth([string]$Name) {
    $status = docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' $Name 2>&1
    if ($LASTEXITCODE -ne 0) { return $null }
    return ($status | Out-String).Trim()
}

function Wait-Healthy([string]$Name, [int]$TimeoutSeconds = 120) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $health = Get-ContainerHealth $Name
        if ($health -eq "healthy") { return $true }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)
    return $false
}

Write-Host "==> Building and starting stack"
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { Fail "docker compose up --build failed" }

Write-Host "==> Waiting for api-gateway to become healthy"
if (-not (Wait-Healthy "earp-api-gateway" 180)) {
    Fail "api-gateway not healthy (status=$(Get-ContainerHealth 'earp-api-gateway'))"
}
Pass "api-gateway is healthy"

Write-Host "==> Checking rag-net membership"
$networkContainers = docker network inspect rag-net --format '{{range .Containers}}{{.Name}} {{end}}'
if ($networkContainers -notmatch "earp-api-gateway") { Fail "api-gateway not on rag-net" }
Pass "api-gateway attached to rag-net"

Write-Host "==> GET /health"
$health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get
if ($health.status -ne "ok") { Fail "/health returned unexpected payload" }
Pass "/health returned 200"

Write-Host "==> GET /api/v1/me without token (expect 401)"
try {
    Invoke-RestMethod -Uri "$BaseUrl/api/v1/me" -Method Get -ErrorAction Stop | Out-Null
    Fail "expected 401 without token"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -ne 401) {
        Fail "expected 401 without token, got $($_.Exception.Response.StatusCode.value__)"
    }
}
Pass "protected endpoint rejected unauthenticated request"

Write-Host "==> POST /api/v1/auth/token"
$tokenBody = @{ sub = "verify-user"; permissions = @("ingest:write", "query:read") } | ConvertTo-Json
$tokenResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/token" -Method Post -Body $tokenBody -ContentType "application/json"
if (-not $tokenResponse.access_token) { Fail "token endpoint did not return access_token" }
$token = $tokenResponse.access_token
Pass "obtained dev JWT"

$headers = @{ Authorization = "Bearer $token" }

Write-Host "==> GET /api/v1/me with token"
$me = Invoke-RestMethod -Uri "$BaseUrl/api/v1/me" -Method Get -Headers $headers
if ($me.sub -ne "verify-user") { Fail "/api/v1/me returned wrong sub: $($me.sub)" }
Pass "/api/v1/me returned identity and permissions"

Write-Host "==> GET /api/v1/health/deps with token"
$deps = Invoke-RestMethod -Uri "$BaseUrl/api/v1/health/deps" -Method Get -Headers $headers
if ($deps.postgres.status -ne "ok") { Fail "postgres probe failed: $($deps.postgres | ConvertTo-Json -Compress)" }
if ($deps.valkey.status -ne "ok") { Fail "valkey probe failed: $($deps.valkey | ConvertTo-Json -Compress)" }
Pass "async dependency probes succeeded"

Write-Host "==> Parallel async probe test (10 concurrent requests)"
$jobs = 1..10 | ForEach-Object {
    Start-Job -ScriptBlock {
        param($Url, $Token)
        try {
            $h = @{ Authorization = "Bearer $Token" }
            $r = Invoke-RestMethod -Uri $Url -Method Get -Headers $h
            if ($r.postgres.status -ne "ok" -or $r.valkey.status -ne "ok") { return $false }
            return $true
        } catch {
            return $false
        }
    } -ArgumentList "$BaseUrl/api/v1/health/deps", $token
}
$results = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job -Force
if (($results | Where-Object { $_ -ne $true }).Count -gt 0) { Fail "one or more concurrent requests failed" }
Pass "10 concurrent async requests succeeded"

Write-Host "==> WebSocket stub test"
docker compose exec -T api-gateway uv run python -m app.ws_smoke_test $token
if ($LASTEXITCODE -ne 0) { Fail "websocket stub test failed" }
Pass "websocket stub returned connected status"

Write-Host "==> SSE stub test"
$sse = Invoke-WebRequest -Uri "$BaseUrl/api/v1/events?token=$token" -Method Get -UseBasicParsing
if ($sse.StatusCode -ne 200) { Fail "SSE endpoint failed" }
if ($sse.Content -notmatch "connected") { Fail "SSE stream missing connected event" }
Pass "SSE stub streamed status events"

Write-Host ""
Write-Host "Sprint 02 verification complete."

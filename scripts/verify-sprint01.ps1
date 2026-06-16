# Sprint 01 acceptance verification for EARP foundation stack.
param(
    [switch]$Gpu
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

if (-not (Test-Path ".env")) {
    Write-Host "Creating .env from .env.example"
    Copy-Item ".env.example" ".env"
}

Get-Content ".env" | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
    }
}

$PostgresPort = if ($env:POSTGRES_PORT) { $env:POSTGRES_PORT } else { "5432" }
$ValkeyPort = if ($env:VALKEY_PORT) { $env:VALKEY_PORT } else { "6379" }
$PostgresUser = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "earp" }
$PostgresDb = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { "earp" }

function Get-ContainerHealth([string]$Name) {
    $status = docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' $Name 2>&1
    if ($LASTEXITCODE -ne 0) { return $null }
    return ($status | Out-String).Trim()
}

function Wait-Healthy([string]$Name, [int]$TimeoutSeconds = 60) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $health = Get-ContainerHealth $Name
        if ($health -eq "healthy") { return $true }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)
    return $false
}

function Pass([string]$Message) { Write-Host "[PASS] $Message" -ForegroundColor Green }
function Fail([string]$Message) { Write-Host "[FAIL] $Message" -ForegroundColor Red; exit 1 }

Write-Host "==> Starting stack"
docker compose up -d
if ($LASTEXITCODE -ne 0) { Fail "docker compose up failed (image pull or startup error)" }

Write-Host "==> Waiting for healthy services (up to 120s)"
if (-not (Wait-Healthy "earp-postgres" 120)) {
    $pgHealth = Get-ContainerHealth "earp-postgres"
    Fail "postgres not healthy (status=$pgHealth)"
}
if (-not (Wait-Healthy "earp-valkey" 120)) {
    $vkHealth = Get-ContainerHealth "earp-valkey"
    Fail "valkey not healthy (status=$vkHealth)"
}
Pass "postgres and valkey are healthy"

Write-Host "==> Checking rag-net membership"
$networkContainers = docker network inspect rag-net --format '{{range .Containers}}{{.Name}} {{end}}'
Write-Host "    containers on rag-net: $networkContainers"
if ($networkContainers -notmatch "earp-postgres") { Fail "postgres not on rag-net" }
if ($networkContainers -notmatch "earp-valkey") { Fail "valkey not on rag-net" }
Pass "both services attached to rag-net"

Write-Host "==> Checking inter-container connectivity"
$valkeyHost = (docker compose exec -T postgres getent hosts valkey).Trim()
if (-not $valkeyHost) { Fail "postgres cannot resolve valkey on rag-net" }
Pass "postgres can resolve valkey on rag-net"

Write-Host "==> Checking Valkey reachability on localhost:$ValkeyPort"
$pong = (docker compose exec -T valkey valkey-cli ping).Trim()
if ($pong -ne "PONG") { Fail "valkey ping expected PONG, got $pong" }
Pass "valkey-cli ping returned PONG"

Write-Host "==> PostgreSQL persistence test"
$sql = @"
CREATE TABLE IF NOT EXISTS sprint01_check (id serial PRIMARY KEY, note text);
TRUNCATE sprint01_check;
INSERT INTO sprint01_check (note) VALUES ('persist');
"@
docker compose exec -T postgres psql -U $PostgresUser -d $PostgresDb -c $sql | Out-Null
docker compose restart postgres | Out-Null
Start-Sleep -Seconds 5
if (-not (Wait-Healthy "earp-postgres" 60)) { Fail "postgres did not become healthy after restart" }
$pgRow = (docker compose exec -T postgres psql -U $PostgresUser -d $PostgresDb -tAc "SELECT note FROM sprint01_check LIMIT 1;").Trim()
if ($pgRow -ne "persist") { Fail "postgres data lost after restart (got '$pgRow')" }
Pass "postgres data persisted across restart"

Write-Host "==> Valkey persistence test"
docker compose exec -T valkey valkey-cli SET sprint01 persist | Out-Null
docker compose restart valkey | Out-Null
Start-Sleep -Seconds 5
if (-not (Wait-Healthy "earp-valkey" 60)) { Fail "valkey did not become healthy after restart" }
$vkVal = (docker compose exec -T valkey valkey-cli GET sprint01).Trim()
if ($vkVal -ne "persist") { Fail "valkey data lost after restart (got '$vkVal')" }
Pass "valkey data persisted across restart"

if ($Gpu) {
    Write-Host "==> GPU smoke test"
    docker compose -f docker-compose.yml -f docker-compose.gpu.yml --profile gpu-test run --rm gpu-smoke-test nvidia-smi
    if ($LASTEXITCODE -ne 0) { Fail "gpu-smoke-test nvidia-smi failed" }
    Pass "gpu-smoke-test nvidia-smi succeeded"
} else {
    Write-Host "==> Skipping GPU smoke test (pass -Gpu to run)"
}

Write-Host ""
Write-Host "Sprint 01 verification complete."

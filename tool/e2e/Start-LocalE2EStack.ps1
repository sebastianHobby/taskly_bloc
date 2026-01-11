param(
    [switch]$ResetDb,
    [int]$PowerSyncPort = 8080
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    throw "Supabase CLI not found on PATH. Install it and restart VS Code."
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker not found on PATH. Install Docker Desktop and retry."
}

Write-Host "Starting Supabase local stack..."
supabase start | Out-Host

if ($ResetDb) {
    Write-Host "Resetting local database (applies migrations + seed.sql)..."
    supabase db reset | Out-Host
}

# Ensure PowerSync env file exists
$envExample = Join-Path $PSScriptRoot "..\..\infra\powersync_local\powersync.env.example"
$envFile = Join-Path $PSScriptRoot "..\..\infra\powersync_local\.env"

$envExample = (Resolve-Path $envExample).Path
$envFile = (Resolve-Path (Split-Path $envFile -Parent)).Path + "\.env"

if (-not (Test-Path $envFile)) {
    Copy-Item -Path $envExample -Destination $envFile -Force
    Write-Host "Created $envFile from template."
}

# Generate local dart defines
$definesPath = Join-Path $PSScriptRoot "..\..\dart_defines.local.json"
$definesPath = (Resolve-Path (Split-Path $definesPath -Parent)).Path + "\dart_defines.local.json"

& (Join-Path $PSScriptRoot "New-LocalE2EDefines.ps1") -OutputPath $definesPath -PowerSyncPort $PowerSyncPort

Write-Host "Starting PowerSync (docker compose)..."
Push-Location (Join-Path $PSScriptRoot "..\..\infra\powersync_local")
try {
    docker compose --env-file .\.env up -d | Out-Host
}
finally {
    Pop-Location
}

Write-Host "Local E2E stack is up."
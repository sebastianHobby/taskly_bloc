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
    Write-Host "Resetting local database (fast truncate)..."
    try {
        & (Join-Path $PSScriptRoot "Truncate-LocalE2EDb.ps1") | Out-Host
    }
    catch {
        Write-Host "Truncate failed (likely missing schema). Pulling schema (supabase db pull), then resetting DB..."

        supabase db pull | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw (
                "supabase db pull failed. This repo does not commit schema migrations; " +
                "you must link the repo to your Supabase project first (supabase link --project-ref <ref>) " +
                "and authenticate (SUPABASE_ACCESS_TOKEN or supabase login)."
            )
        }

        supabase db reset | Out-Host
        & (Join-Path $PSScriptRoot "Truncate-LocalE2EDb.ps1") | Out-Host
    }

    # Validate expected tables exist. If not, the repo likely lacks schema migrations.
    $dbContainer = (docker ps --filter "name=supabase_db" --format "{{.ID}}" | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($dbContainer)) {
        throw "Could not find Supabase Postgres container (name filter: supabase_db)."
    }

    $existsSql = "select " +
    "coalesce(to_regclass('public.values')::text,'') || '|' || " +
    "coalesce(to_regclass('public.projects')::text,'') || '|' || " +
    "coalesce(to_regclass('public.tasks')::text,'') || '|' || " +
    "coalesce(to_regclass('public.user_profiles')::text,'');"

    $tablesLine = (docker exec $dbContainer psql -U postgres -d postgres -Atc $existsSql)
    if ($tablesLine -eq '|||') {
        throw (
            "Local Supabase schema is missing the app tables required for E2E tests. " +
            "Run 'supabase db pull' (after linking/auth), then rerun this script."
        )
    }
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
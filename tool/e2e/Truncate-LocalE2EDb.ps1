param(
    [string]$SqlPath = "supabase\\truncate_pipeline.sql"
)

$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..\\..')
Set-Location $root

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker not found on PATH. Install Docker Desktop and retry."
}

$sqlFullPath = Join-Path $root $SqlPath
if (-not (Test-Path $sqlFullPath)) {
    throw "SQL file not found: $sqlFullPath"
}

# Find the Supabase Postgres container.
# Supabase CLI usually names it like: supabase_db_<project>
$containerId = (docker ps --filter "name=supabase_db" --format "{{.ID}}" | Select-Object -First 1)
if ([string]::IsNullOrWhiteSpace($containerId)) {
    throw "Could not find a running Supabase Postgres container (name filter: supabase_db). Is 'supabase start' running?"
}

Write-Host "Truncating app tables via container $containerId ..."

# Pipe the SQL into psql inside the container.
# Use ON_ERROR_STOP for reliable failures.
$null = Get-Content -Raw $sqlFullPath |
docker exec -i $containerId psql -U postgres -d postgres -v ON_ERROR_STOP=1

if ($LASTEXITCODE -ne 0) {
    throw "psql exited with code $LASTEXITCODE while truncating tables"
}

Write-Host 'Truncate completed.'

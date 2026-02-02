param(
  [switch]$ResetDb,
  [int]$PowerSyncPort = 8080,
  [string]$Device = "windows",
  [string]$Entrypoint = "integration_test/powersync_pipeline_entrypoint_test.dart"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    throw "Supabase CLI not found on PATH. Install it and retry."
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker not found on PATH. Install Docker Desktop and retry."
}

function Test-SupabaseRunning {
    try {
        $statusJson = supabase status -o json | ConvertFrom-Json
        return -not [string]::IsNullOrWhiteSpace($statusJson.api.url)
    }
    catch {
        return $false
    }
}

function Get-ContainerId {
    param([string]$Name)
    return docker ps --filter "name=$Name" --format "{{.ID}}" | Select-Object -First 1
}

function Test-ContainerHealthy {
    param([string]$Name)

    $id = Get-ContainerId -Name $Name
    if ([string]::IsNullOrWhiteSpace($id)) {
        return $false
    }

    try {
        $health = docker inspect --format "{{.State.Health.Status}}" $id 2>$null
        if ([string]::IsNullOrWhiteSpace($health) -or $health -eq "<no value>") {
            return $true
        }
        return $health -eq "healthy"
    }
    catch {
        return $true
    }
}

$supabaseOk = Test-SupabaseRunning
$powersyncOk = Test-ContainerHealthy -Name "powersync_local-powersync-1"

if ($ResetDb -or -not $supabaseOk -or -not $powersyncOk) {
    & (Join-Path $PSScriptRoot "Start-LocalE2EStack.ps1") -ResetDb:$ResetDb -PowerSyncPort $PowerSyncPort
}

Write-Host "Waiting for PowerSync liveness..."
$deadline = (Get-Date).AddMinutes(2)
while ((Get-Date) -lt $deadline) {
    try {
        $resp = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$PowerSyncPort/probes/liveness"
        if ($resp.StatusCode -eq 200) { break }
    }
    catch { }
    Start-Sleep -Seconds 2
}

Write-Host "Running pipeline integration tests (device: $Device)..."
Write-Host "Note: pipeline tests are integration-test-only and require the integration test binding."
flutter test $Entrypoint -d $Device | Out-Host

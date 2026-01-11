param(
    [string]$OutputPath = "dart_defines.local.json",
    [int]$PowerSyncPort = 8080
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    throw "Supabase CLI not found on PATH. Install it and restart VS Code."
}

$raw = supabase status -o json
$status = $raw | ConvertFrom-Json

# Expected keys (Supabase CLI): api_url, anon_key
$supabaseUrl = $status.api_url
$anonKey = $status.anon_key

if ([string]::IsNullOrWhiteSpace($supabaseUrl)) {
    throw "supabase status did not return api_url. Is the local stack running (supabase start)?"
}
if ([string]::IsNullOrWhiteSpace($anonKey)) {
    throw "supabase status did not return anon_key. Is the local stack running (supabase start)?"
}

$powersyncUrl = "http://localhost:$PowerSyncPort"

$defines = [ordered]@{
    SUPABASE_URL             = $supabaseUrl
    SUPABASE_PUBLISHABLE_KEY = $anonKey
    POWERSYNC_URL            = $powersyncUrl
    DEV_USERNAME             = ""
    DEV_PASSWORD             = ""
}

$defines | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Wrote $OutputPath"
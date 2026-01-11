param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRef
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
  throw "Supabase CLI not found on PATH. Install it and restart VS Code."
}

Write-Host "Linking Supabase project..."
supabase link --project-ref $ProjectRef | Out-Host

Write-Host "Pulling remote schema into supabase/migrations..."
Write-Host "Review the generated migration(s) and commit them intentionally."
supabase db pull | Out-Host

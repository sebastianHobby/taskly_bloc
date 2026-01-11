param(
  [switch]$ResetDb,
  [int]$PowerSyncPort = 8080
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot "Start-LocalE2EStack.ps1") -ResetDb:$ResetDb -PowerSyncPort $PowerSyncPort

Write-Host "Running Flutter tests against local stack..."
flutter test test/integration_test --dart-define-from-file=dart_defines.local.json | Out-Host

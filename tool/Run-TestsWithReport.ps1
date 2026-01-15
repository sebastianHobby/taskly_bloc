param(
    [switch]$Utc
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$baseReportPath = Join-Path $repoRoot 'test\last_run.json'

$stamp = if ($Utc) {
    (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss'Z'")
}
else {
    (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss'Z'")
}

$datedReportPath = Join-Path $repoRoot ("test\last_run_$stamp.json")

Write-Host "Running flutter test...";

flutter test @args
$exitCode = $LASTEXITCODE

if (Test-Path -LiteralPath $baseReportPath) {
    Copy-Item -LiteralPath $baseReportPath -Destination $datedReportPath -Force
    Write-Host "Wrote: $datedReportPath"
}
else {
    Write-Host "No file reporter output found at: $baseReportPath"
}

exit $exitCode

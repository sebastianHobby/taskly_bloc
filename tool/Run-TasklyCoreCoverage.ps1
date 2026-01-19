param(
    [double]$Min = 80
)

$ErrorActionPreference = 'Stop'

Push-Location (Join-Path $PSScriptRoot '..\packages\taskly_core')
try {
    flutter test --coverage
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    dart run ..\..\tool\taskly_core_coverage.dart --input=coverage\lcov.info --min=$Min
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}

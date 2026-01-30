Param(
  [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'

Write-Host '== dart analyze =='
dart analyze

Write-Host '== guardrails =='
dart run tool/guardrails.dart

if (-not $SkipTests) {
  Write-Host '== tests (fast loop) =='
  flutter test -x integration -x slow -x repository -x flaky -x pipeline -x diagnosis
}

Write-Host 'Quickcheck complete.'

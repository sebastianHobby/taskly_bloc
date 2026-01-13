param(
    [Parameter(Mandatory = $true)]
    [string]$LockName
)

$ErrorActionPreference = 'Stop'

$lockRoot = Join-Path $PSScriptRoot '..\build_out\task_locks'
$lockRoot = (Resolve-Path -Path $lockRoot -ErrorAction SilentlyContinue)?.Path ?? $lockRoot

if (-not (Test-Path -LiteralPath $lockRoot)) {
    New-Item -ItemType Directory -Path $lockRoot -Force | Out-Null
}

$lockFile = Join-Path $lockRoot ("$LockName.json")

# Exit code used when a lock is held by a live process.
# Keep this in sync with tool/test_run_recorder.dart.
$AlreadyRunningExitCode = 42

function Get-LockContent {
    param([string]$Path)

    try {
        $raw = Get-Content -LiteralPath $Path -Raw
        return $raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

# Determine command tokens from remaining args.
$delimIndex = [Array]::IndexOf($args, '--')
if ($delimIndex -ge 0) {
    $commandTokens = @($args[($delimIndex + 1)..($args.Length - 1)])
}
else {
    $commandTokens = @($args)
}

if ($commandTokens.Count -eq 0) {
    Write-Error 'No command provided. Usage: task_guard.ps1 -LockName <name> -- <command> [args...]'
}

if (Test-Path -LiteralPath $lockFile) {
    $lock = Get-LockContent -Path $lockFile
    $pid = $lock?.pid

    if ($pid -is [int] -and $pid -gt 0) {
        $existing = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($null -ne $existing) {
            Write-Host "Task '$LockName' already running (pid=$pid)."
            exit $AlreadyRunningExitCode
        }
    }

    # Stale or unreadable lock
    Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
}

$lockObj = [pscustomobject]@{
    lockName = $LockName
    pid      = $PID
    started  = (Get-Date).ToUniversalTime().ToString('o')
    command  = $commandTokens
}

$lockObj | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $lockFile -Encoding UTF8

try {
    $exe = $commandTokens[0]
    $exeArgs = @()
    if ($commandTokens.Count -gt 1) {
        $exeArgs = @($commandTokens[1..($commandTokens.Count - 1)])
    }

    & $exe @exeArgs
    exit $LASTEXITCODE
}
finally {
    Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
}

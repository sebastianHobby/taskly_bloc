param(
    [int]$Iterations = 3,
    [switch]$IncludeStartup,
    [switch]$ResetDb,
    [int]$PowerSyncPort = 8080,
    [string]$Reporter = 'expanded'
)

$ErrorActionPreference = 'Stop'

function Get-MedianSeconds {
    param([double[]]$Values)
    if (-not $Values -or $Values.Count -eq 0) { return [double]::NaN }

    $sorted = $Values | Sort-Object
    $n = $sorted.Count
    if ($n % 2 -eq 1) {
        return [double]$sorted[($n - 1) / 2]
    }

    $a = [double]$sorted[($n / 2) - 1]
    $b = [double]$sorted[$n / 2]
    return ($a + $b) / 2.0
}

function Format-Stats {
    param([double[]]$Seconds)

    $clean = $Seconds | Where-Object { -not [double]::IsNaN($_) }
    if (-not $clean -or $clean.Count -eq 0) {
        return 'no successful runs'
    }

    $min = ($clean | Measure-Object -Minimum).Minimum
    $max = ($clean | Measure-Object -Maximum).Maximum
    $median = Get-MedianSeconds -Values $clean

    return ('min={0:N2}s median={1:N2}s max={2:N2}s (n={3})' -f $min, $median, $max, $clean.Count)
}

function Invoke-Measured {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Block,
        [int]$Count = 3
    )

    Write-Host ''
    Write-Host "== $Name =="

    $results = @()

    for ($i = 1; $i -le $Count; $i++) {
        Write-Host "Run $i/$Count ..." -NoNewline
        try {
            $duration = Measure-Command { & $Block }
            $seconds = [double]$duration.TotalSeconds
            $results += $seconds
            Write-Host (" ok ({0:N2}s)" -f $seconds)
        }
        catch {
            $results += [double]::NaN
            Write-Host ' FAILED'
            Write-Host "  $($_.Exception.Message)"
        }
    }

    Write-Host ("Stats: {0}" -f (Format-Stats -Seconds $results))

    return , $results
}

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $root

Write-Host "Repo root: $root"
Write-Host "Iterations: $Iterations"

if ($IncludeStartup) {
    $startup = Invoke-Measured -Name 'Local stack startup (Supabase + PowerSync)' -Count 1 -Block {
        & (Join-Path $PSScriptRoot 'Start-LocalE2EStack.ps1') -ResetDb:$ResetDb -PowerSyncPort $PowerSyncPort
    }
}

$excludePipeline = Invoke-Measured -Name 'flutter test (exclude pipeline tag)' -Count $Iterations -Block {
    flutter test --exclude-tags=pipeline --reporter=$Reporter | Out-Host
}

$pipelineOnly = Invoke-Measured -Name 'flutter test (pipeline tag only)' -Count $Iterations -Block {
    flutter test --tags=pipeline --reporter=$Reporter | Out-Host
}

Write-Host ''
Write-Host '== Summary =='
Write-Host ("Exclude pipeline: {0}" -f (Format-Stats -Seconds $excludePipeline))
Write-Host ("Pipeline only:    {0}" -f (Format-Stats -Seconds $pipelineOnly))

$excludeMedian = Get-MedianSeconds -Values ($excludePipeline | Where-Object { -not [double]::IsNaN($_) })
$pipelineMedian = Get-MedianSeconds -Values ($pipelineOnly | Where-Object { -not [double]::IsNaN($_) })

if (-not [double]::IsNaN($excludeMedian) -and -not [double]::IsNaN($pipelineMedian)) {
    Write-Host ("Median delta (pipeline - exclude): {0:N2}s" -f ($pipelineMedian - $excludeMedian))
}
else {
    Write-Host 'Median delta: unavailable (need successful runs in both suites).'
}

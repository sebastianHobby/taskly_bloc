param(
    [string]$CoveragePackage = 'taskly',
    [switch]$NoPub
)

$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
    param(
        [string]$StartDir
    )

    $dir = Resolve-Path $StartDir
    while ($true) {
        if (Test-Path (Join-Path $dir 'pubspec.yaml')) {
            return $dir
        }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
    }

    return $null
}

$repoRoot = Get-RepoRoot -StartDir (Get-Location)
if (-not $repoRoot) {
    $repoRoot = Get-RepoRoot -StartDir (Join-Path $PSScriptRoot '..')
}
if (-not $repoRoot) {
    throw 'Could not locate repo root (pubspec.yaml). Run from inside the repo.'
}

Push-Location $repoRoot
try {
    $coverageDir = Join-Path $repoRoot 'coverage'
    New-Item -ItemType Directory -Force -Path $coverageDir | Out-Null

    # Keep the default regex simple to avoid Windows cmd pipe parsing.
    $flutterArgs = @('test', '--coverage', "--coverage-package=$CoveragePackage")
    if ($NoPub) {
        $flutterArgs += '--no-pub'
    }
    flutter @flutterArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $rootCoverage = Join-Path $coverageDir 'lcov_root.info'
    $rootLcov = Join-Path $coverageDir 'lcov.info'
    if (Test-Path $rootLcov) {
        Copy-Item $rootLcov $rootCoverage -Force
    } else {
        Write-Warning 'Root coverage/lcov.info not found.'
    }

    $lcovInputs = @()
    if (Test-Path $rootCoverage) { $lcovInputs += $rootCoverage }

    $packagesDir = Join-Path $repoRoot 'packages'
    if (Test-Path $packagesDir) {
        $packageDirs = Get-ChildItem $packagesDir -Directory | Where-Object {
            Test-Path (Join-Path $_.FullName 'pubspec.yaml')
        }

        foreach ($pkg in $packageDirs) {
            Push-Location $pkg.FullName
            try {
                flutter @flutterArgs
                if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

                $pkgLcov = Join-Path $pkg.FullName 'coverage\lcov.info'
                if (Test-Path $pkgLcov) {
                    $dest = Join-Path $coverageDir ("lcov_{0}.info" -f $pkg.Name)
                    Copy-Item $pkgLcov $dest -Force
                    $lcovInputs += $dest
                } else {
                    Write-Warning ("{0}: coverage/lcov.info not found." -f $pkg.Name)
                }
            }
            finally {
                Pop-Location
            }
        }
    }

    $inputsArg = ($lcovInputs -join ',')
    dart run tool/coverage_merge.dart --inputs="$inputsArg" --output=coverage/lcov_merged.info
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    dart run tool/coverage_filter.dart --input=coverage/lcov_merged.info --output=coverage/lcov_filtered.info
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    dart run tool/coverage_summary.dart coverage/lcov_filtered.info
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $genhtml = Get-Command genhtml -ErrorAction SilentlyContinue
    if ($null -ne $genhtml) {
        genhtml coverage/lcov_filtered.info -o coverage/html | Out-Null
        Write-Host 'HTML report: coverage/html/index.html'
    } else {
        Write-Warning 'genhtml not found; skip HTML report (install lcov to enable).'
    }
}
finally {
    Pop-Location
}

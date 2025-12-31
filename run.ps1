# Helper script to run Flutter app with environment variables from .env file
# Usage: .\run.ps1 [device]
# Example: .\run.ps1 windows

param(
    [string]$Device = ""
)

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "Error: .env file not found. Please create one with your environment variables." -ForegroundColor Red
    Write-Host ""
    Write-Host "Example .env file:" -ForegroundColor Yellow
    Write-Host "SUPABASE_URL=https://your-project.supabase.co"
    Write-Host "SUPABASE_PUBLISHABLE_KEY=your-key-here"
    Write-Host "POWERSYNC_URL=https://your-instance.powersync.com"
    Write-Host "DEV_USERNAME=admin@example.com"
    Write-Host "DEV_PASSWORD=yourpassword"
    exit 1
}

# Read .env file and build dart-define arguments
$dartDefines = @()
Get-Content ".env" | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        if ($line -match '^([^=]+)=(.*)$') {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            $dartDefines += "--dart-define=$key=$value"
        }
    }
}

# Build flutter run command
$command = "flutter run"
if ($Device) {
    $command += " -d $Device"
}

# Add all dart-define flags
$fullCommand = "$command $($dartDefines -join ' ')"

Write-Host "Running: $fullCommand" -ForegroundColor Green
Write-Host ""

# Execute the command
Invoke-Expression $fullCommand

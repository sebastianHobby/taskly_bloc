param(
  [Parameter(Mandatory = $true)]
  [string]$LogPath,
  [int]$Days = 7
)

if (-not (Test-Path $LogPath)) {
  throw "Log file not found: $LogPath"
}

$content = Get-Content -Path $LogPath -Raw
$chunks = $content -split "(?m)^---\s*$"
$cutoff = (Get-Date).ToUniversalTime().AddDays(-$Days)

$warningCount = 0
$errorCount = 0
$handleCount = 0
$warningMessages = @{}

foreach ($chunk in $chunks) {
  $entry = $chunk.Trim()
  if ([string]::IsNullOrWhiteSpace($entry)) {
    continue
  }

  $lines = $entry -split "`r?`n"
  if ($lines.Count -lt 2) {
    continue
  }

  # Expected first line: [LEVEL] 2026-01-01T12:00:00.000Z
  $header = $lines[0]
  $match = [regex]::Match($header, '^\[(?<level>[A-Z_]+)\]\s+(?<ts>\S+)')
  if (-not $match.Success) {
    continue
  }

  $level = $match.Groups['level'].Value
  $timestampText = $match.Groups['ts'].Value

  try {
    $ts = [DateTime]::Parse($timestampText).ToUniversalTime()
  } catch {
    continue
  }

  if ($ts -lt $cutoff) {
    continue
  }

  $message = $lines[1].Trim()

  switch ($level) {
    'WARNING' {
      $warningCount++
      if ($warningMessages.ContainsKey($message)) {
        $warningMessages[$message] = $warningMessages[$message] + 1
      } else {
        $warningMessages[$message] = 1
      }
    }
    'ERROR' {
      $errorCount++
    }
    'EXCEPTION' {
      $handleCount++
    }
    default {
      # Ignore other levels for this snapshot.
    }
  }
}

$uniqueWarningCount = $warningMessages.Keys.Count
$warningDuplicateRate = if ($warningCount -eq 0) {
  0.0
} else {
  [math]::Round((($warningCount - $uniqueWarningCount) / $warningCount), 4)
}

$topWarnings = @($warningMessages.GetEnumerator() |
  Sort-Object -Property Value -Descending |
  Select-Object -First 20 |
  ForEach-Object {
    [PSCustomObject]@{
      count = $_.Value
      message = $_.Key
    }
  })

$result = [PSCustomObject]@{
  window_days = $Days
  cutoff_utc = $cutoff.ToString('o')
  totals = [PSCustomObject]@{
    warning = $warningCount
    error = $errorCount
    handle = $handleCount
  }
  unique_warning_messages = $uniqueWarningCount
  warning_duplicate_rate = $warningDuplicateRate
  top_warning_messages = $topWarnings
}

$result | ConvertTo-Json -Depth 5

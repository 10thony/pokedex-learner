Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envFile = Join-Path $repoRoot ".env.local"

if (!(Test-Path $envFile)) {
  throw ".env.local is missing. Run infra/bootstrap.ps1 first."
}

$url = ""
$adminKey = ""

Get-Content $envFile | ForEach-Object {
  if ($_ -match "^\s*CONVEX_SELF_HOSTED_URL\s*=\s*'?([^']+)'?\s*$") {
    $url = $matches[1]
  } elseif ($_ -match "^\s*CONVEX_SELF_HOSTED_ADMIN_KEY\s*=\s*'?([^']+)'?\s*$") {
    $adminKey = $matches[1]
  }
}

if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($adminKey)) {
  throw "CONVEX_SELF_HOSTED_URL or CONVEX_SELF_HOSTED_ADMIN_KEY not found in .env.local"
}

Push-Location $repoRoot
try {
  $env:CONVEX_SELF_HOSTED_URL = $url
  $env:CONVEX_SELF_HOSTED_ADMIN_KEY = $adminKey

  Write-Host "Running duplicate-name cleanup migration..."
  npx convex@latest run pokedex:dedupeByNameMigration '{"dryRun":false}'
} finally {
  Pop-Location
}

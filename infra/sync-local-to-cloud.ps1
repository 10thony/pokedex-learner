param(
  [string]$CloudDeployment = "resilient-orca-880",
  [string]$SnapshotOut = "data/convex-local-export.zip"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envFile = Join-Path $repoRoot ".env.local"
$snapshotPath = Join-Path $repoRoot $SnapshotOut
$snapshotDir = Split-Path -Parent $snapshotPath

if (!(Test-Path $envFile)) {
  throw ".env.local is missing. Expected local Convex credentials for export."
}

if (!(Test-Path $snapshotDir)) {
  New-Item -ItemType Directory -Path $snapshotDir | Out-Null
}

$localUrl = ""
$localAdminKey = ""

Get-Content $envFile | ForEach-Object {
  if ($_ -match "^\s*CONVEX_SELF_HOSTED_URL\s*=\s*'?([^']+)'?\s*$") {
    $localUrl = $matches[1]
  } elseif ($_ -match "^\s*CONVEX_SELF_HOSTED_ADMIN_KEY\s*=\s*'?([^']+)'?\s*$") {
    $localAdminKey = $matches[1]
  }
}

if ([string]::IsNullOrWhiteSpace($localUrl) -or [string]::IsNullOrWhiteSpace($localAdminKey)) {
  throw "CONVEX_SELF_HOSTED_URL or CONVEX_SELF_HOSTED_ADMIN_KEY not found in .env.local"
}

Push-Location $repoRoot
try {
  Write-Host "Exporting local Convex snapshot from $localUrl ..."
  $env:CONVEX_SELF_HOSTED_URL = $localUrl
  $env:CONVEX_SELF_HOSTED_ADMIN_KEY = $localAdminKey
  npx convex@latest export --path $SnapshotOut
  if ($LASTEXITCODE -ne 0 -or !(Test-Path $snapshotPath)) {
    throw "Local snapshot export failed. Verify local Convex is reachable at $localUrl."
  }

  Write-Host "Importing snapshot into cloud deployment '$CloudDeployment' ..."
  Remove-Item Env:CONVEX_SELF_HOSTED_URL -ErrorAction SilentlyContinue
  Remove-Item Env:CONVEX_SELF_HOSTED_ADMIN_KEY -ErrorAction SilentlyContinue
  npx convex@latest import --deployment $CloudDeployment --replace-all --yes $SnapshotOut
  if ($LASTEXITCODE -ne 0) {
    throw "Cloud import failed for deployment '$CloudDeployment'."
  }

  Write-Host "Cloud sync complete."
} finally {
  Pop-Location
}

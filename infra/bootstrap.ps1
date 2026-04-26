Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$infraDir = Resolve-Path $PSScriptRoot
$envFile = Join-Path $repoRoot ".env.local"

docker compose -f (Join-Path $infraDir "docker-compose.yml") up -d

$rawKeyOutput = docker compose -f (Join-Path $infraDir "docker-compose.yml") exec -T backend ./generate_admin_key.sh
$adminKeyMatch = $rawKeyOutput | Select-String "convex-self-hosted\|\S+"
$adminKey = $adminKeyMatch.Matches.Value

if ([string]::IsNullOrWhiteSpace($adminKey)) {
  throw "Failed to parse Convex admin key."
}

$lines = @(
  "CONVEX_SELF_HOSTED_URL=http://127.0.0.1:3210"
  "CONVEX_SELF_HOSTED_ADMIN_KEY=$adminKey"
)

Set-Content -Path $envFile -Value $lines
Write-Host "Wrote $envFile"

Write-Host "Convex dashboard: http://localhost:6791"
Write-Host "Convex backend:   http://127.0.0.1:3210"
Write-Host "Now run: powershell -ExecutionPolicy Bypass -File infra/seed-pokedex.ps1"

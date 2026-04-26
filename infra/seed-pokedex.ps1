Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$dataDir = Join-Path $repoRoot "data"
$pokedexDir = Join-Path $dataDir "pokedex"
$sourceTsv = Join-Path $pokedexDir "data\pokemon.csv"
$seedCsv = Join-Path $pokedexDir "data\pokemon.comma.csv"
$envFile = Join-Path $repoRoot ".env.local"

if (!(Test-Path $dataDir)) {
  New-Item -ItemType Directory -Path $dataDir | Out-Null
}

if (!(Test-Path $pokedexDir)) {
  git clone https://github.com/cristobalmitchell/pokedex.git $pokedexDir
} else {
  Write-Host "Dataset repo already exists at data/pokedex."
}

if (!(Test-Path $sourceTsv)) {
  throw "Expected dataset file not found: $sourceTsv"
}

Import-Csv -Path $sourceTsv -Delimiter "`t" | Export-Csv -Path $seedCsv -NoTypeInformation
Write-Host "Prepared seed CSV: $seedCsv"

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

$containerUrl = $url -replace "127\.0\.0\.1", "host.docker.internal" -replace "localhost", "host.docker.internal"

docker run --rm `
  -e "CONVEX_SELF_HOSTED_URL=$containerUrl" `
  -e "CONVEX_SELF_HOSTED_ADMIN_KEY=$adminKey" `
  -v "${repoRoot}:/app" `
  -w /app `
  node:22 `
  npx convex@latest import --table pokedex --replace --yes data/pokedex/data/pokemon.comma.csv

Write-Host "Seeded Convex table 'pokedex' from dataset."

# pokedex-learner

Self-hosted Convex + Pokemon dataset seed scripts.

## Prereqs

- Docker Desktop
- Git
- PowerShell (Windows)

## Quick start (new laptop)

From repo root:

```powershell
powershell -ExecutionPolicy Bypass -File infra/bootstrap.ps1
powershell -ExecutionPolicy Bypass -File infra/seed-pokedex.ps1
```

What this does:

1. Starts self-hosted Convex (`infra/docker-compose.yml`).
2. Generates an admin key and writes `.env.local`.
3. Clones dataset repo to `data/pokedex` if missing.
4. Imports Pokemon data into Convex table `pokedex` (replace mode).

## Clone and restore submodules

`apps/card-tower` is tracked as a Git submodule. On a fresh machine:

```powershell
git clone https://github.com/10thony/pokedex-learner.git
cd pokedex-learner
git submodule update --init --recursive
```

If you cloned before the submodule was added:

```powershell
git pull
git submodule sync --recursive
git submodule update --init --recursive
```

## Convex foundation

The project now includes a typed Convex schema in `convex/schema.ts` and starter typed
queries in `convex/pokedex.ts` for:

- fetching one Pokemon by dex number (`getByDexNumber`)
- listing Pokemon by primary type with pagination (`listByType`)

Run `npx convex dev` from repo root to generate `convex/_generated/*` type files.

## PokiStack app

```powershell
cd apps/card-tower
npm install
npm run dev
```

`npm run dev` serves the game at `http://localhost:4321` (single server, no Vite port needed).

Modern Vite app (recommended for Netlify and cloud Convex):

```powershell
cd apps/card-tower
pnpm install
pnpm run dev:web
```

This serves the React app at `http://localhost:4322`, with the game route at
`http://localhost:4322/54321`.

Optional production build:

```powershell
npm run build
npm run start
```

## Netlify publish setup

The repo includes `netlify.toml` configured to publish only the modern app:

- Base: `apps/card-tower`
- Build command: `pnpm build`
- Publish directory: `dist`

Legacy assets are kept under `apps/card-tower/legacy` and excluded via
`apps/card-tower/.netlifyignore`.

For SPA routing on Netlify, `apps/card-tower/public/_redirects` rewrites all
paths to `index.html`.

## Convex cloud connection + seeding

Cloud URLs for this project:

- Convex URL: `https://resilient-orca-880.convex.cloud`
- HTTP Actions URL: `https://resilient-orca-880.convex.site`

For local React testing against cloud, set:

```powershell
cd apps/card-tower
echo VITE_CONVEX_URL=https://resilient-orca-880.convex.cloud > .env.local
pnpm run dev:web
```

### Seed cloud directly from local Convex

1. Ensure your local self-hosted Convex is running and seeded.
2. Log in to Convex CLI for cloud access:

```powershell
npx convex@latest login
```

3. Run the sync script:

```powershell
powershell -ExecutionPolicy Bypass -File infra/sync-local-to-cloud.ps1 -CloudDeployment resilient-orca-880
```

This exports a local snapshot and imports it into the cloud deployment with
`--replace-all`.

## Useful commands

- Restart infra:

```powershell
docker compose -f infra/docker-compose.yml up -d
```

- Stop infra:

```powershell
docker compose -f infra/docker-compose.yml down
```

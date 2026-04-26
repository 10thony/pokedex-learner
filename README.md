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

## Convex foundation

The project now includes a typed Convex schema in `convex/schema.ts` and starter typed
queries in `convex/pokedex.ts` for:

- fetching one Pokemon by dex number (`getByDexNumber`)
- listing Pokemon by primary type with pagination (`listByType`)

Run `npx convex dev` from repo root to generate `convex/_generated/*` type files.

## Card Tower app (React + TypeScript)

The `apps/card-tower` app has been migrated to React + TypeScript with Vite.

```powershell
cd apps/card-tower
npm install
npm run dev
```

Optional production build:

```powershell
npm run build
npm run server
```

## Useful commands

- Restart infra:

```powershell
docker compose -f infra/docker-compose.yml up -d
```

- Stop infra:

```powershell
docker compose -f infra/docker-compose.yml down
```

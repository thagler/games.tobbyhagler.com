# games.tobbyhagler.com

Showcase site for playable web game builds and upcoming releases.

## Repository layout

- `index.html` static landing page for GitHub Pages
- `src/` showcase source modules (future app code)
- `public/` showcase static assets
- `tests/` showcase tests
- `games/` deployed game builds (`games/<slug>/`)
- `game-planning/` reusable planning docs, skills, and orchestration rules

## Local preview

```bash
python3 -m http.server 8080
```

Then open <http://localhost:8080>.

## Deploy a game build

Publish a built game into `games/<slug>/`:

```bash
scripts/deploy-game-build.sh <game-slug> <path-to-build-output>
```

Example:

```bash
scripts/deploy-game-build.sh space-runner ../space-runner/dist
```

Requirements:
- Build output must contain `index.html`.
- Slug must use lowercase letters, numbers, and hyphens.

The resulting game URL path is `/games/<game-slug>/`.

## Cloudflare cache purge

This repo includes a GitHub Actions workflow at `.github/workflows/purge-cloudflare-cache.yml` that purges Cloudflare cache for `games.tobbyhagler.com` on each push to `main` (and on manual dispatch).

Required GitHub repository secrets:

- `CLOUDFLARE_ZONE_ID`
- `CLOUDFLARE_API_TOKEN`

Recommended Cloudflare API token scope:

- Zone: `tobbyhagler.com`
- Permissions: `Cache Purge:Edit` (and optionally `Zone:Read`)

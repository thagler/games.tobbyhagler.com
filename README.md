# games.tobbyhagler.com

Showcase site for playable web game builds and upcoming releases, plus active prototype source for Salvage Frontier iOS development.

## Repository layout

- `index.html` static landing page for GitHub Pages
- `src/` source projects
- `src/salvage-frontier-ios/` native iOS SpriteKit prototype for Salvage Frontier
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

## Salvage Frontier iOS prototype

The active iOS prototype lives in `src/salvage-frontier-ios/`.

Build from CLI:

```bash
xcodebuild -project src/salvage-frontier-ios/SalvageFrontier.xcodeproj \
  -scheme SalvageFrontier \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/sf-derived build
```

Run in simulator:

```bash
xcrun simctl boot 'iPhone 16e' || true
xcrun simctl bootstatus 'iPhone 16e' -b
xcrun simctl install 'iPhone 16e' /tmp/sf-derived/Build/Products/Debug-iphonesimulator/SalvageFrontier.app
xcrun simctl launch 'iPhone 16e' com.tobbyhagler.salvagefrontier
```

## Cloudflare cache purge

This repo includes a GitHub Actions workflow at `.github/workflows/purge-cloudflare-cache.yml` that purges Cloudflare cache for `games.tobbyhagler.com` on each push to `main` (and on manual dispatch).

Required GitHub repository secrets:

- `CLOUDFLARE_ZONE_ID`
- `CLOUDFLARE_API_TOKEN`

Recommended Cloudflare API token scope:

- Zone: `tobbyhagler.com`
- Permissions: `Cache Purge:Edit` (and optionally `Zone:Read`)

Manual debug option:

- In GitHub Actions, run `Purge Cloudflare Cache` with `purge_everything=true` to force a full-zone cache purge if host purge is rejected by Cloudflare plan/policy.

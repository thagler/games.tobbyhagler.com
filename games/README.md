# Games Directory

This directory contains published static game builds served by GitHub Pages.

## Layout

- `games/<slug>/index.html`
- `games/<slug>/assets/...`

Each slug should be stable because it becomes part of the public URL.

## Publish a build

From repository root:

```bash
scripts/deploy-game-build.sh <game-slug> <path-to-build-output>
```

Example:

```bash
scripts/deploy-game-build.sh neon-runner ../neon-runner/dist
```

The script clears previous files in `games/<slug>/` before copying the new build output.

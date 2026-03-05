#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/deploy-game-build.sh <game-slug> <build-dir>

Deploy a static game build into games/<game-slug>/ for GitHub Pages.

Arguments:
  game-slug  Lowercase slug, letters/numbers/hyphens only (example: neon-runner)
  build-dir  Path to build output containing index.html
USAGE
}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

slug="$1"
build_dir="$2"

if [[ ! "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Error: invalid game slug '$slug'. Use lowercase letters, numbers, and hyphens only." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

if [[ ! -d "$build_dir" ]]; then
  echo "Error: build directory not found: $build_dir" >&2
  exit 1
fi

source_dir="$(cd "$build_dir" && pwd)"
if [[ ! -f "$source_dir/index.html" ]]; then
  echo "Error: build directory must include index.html: $source_dir" >&2
  exit 1
fi

target_dir="$repo_root/games/$slug"
mkdir -p "$target_dir"

# Clear old deployment contents (including dotfiles) before copying the new build.
find "$target_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
cp -R "$source_dir"/. "$target_dir"/

echo "Deployed '$slug' to $target_dir"
echo "Play URL path: /games/$slug/"

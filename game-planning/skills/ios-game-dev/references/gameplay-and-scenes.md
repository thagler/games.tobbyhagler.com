# Gameplay and Scene Patterns (iOS Native)

## 2D Structure

- Use SpriteKit scenes for rendering boundaries.
- Keep gameplay rules and state transitions independent from scene drawing code.
- Use GameplayKit state machines for menu/play/pause/fail transitions.

## Tile and Scroller Games

- Use tile maps with explicit layers (`visual`, `collision`, `triggers`).
- Keep movement and collision deterministic per frame step.
- Track camera constraints separately from player movement logic.

## Isometric with One-Level Terrain

- Represent terrain height as discrete tile metadata (single-step hills/valleys).
- Derive render ordering from `tileY`, `tileX`, and `height` consistently.
- Keep pathfinding cost map aware of height transitions.

## Performance Notes

- Batch textures via atlases.
- Avoid high-frequency node creation during gameplay loops.
- Prefer pooled objects for repeated effects/projectiles.

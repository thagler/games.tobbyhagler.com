---
name: ios-game-dev
description: Build and validate native iOS games with SpriteKit/GameplayKit, animation systems, haptics, and monetization features while preserving performance and playability. Use when tasks involve 2D gameplay loops, tile/map or scroller/isometric scenes, sprite/effects animation, Core Haptics integration, StoreKit in-app purchases, ad SDK integration, and game-specific QA.
---

# iOS Game Dev

Use this skill to implement and test native iOS game functionality on top of the base iOS app workflow.

## Dependencies

- ios-app-dev

## Contract

- Scope: native iOS game mechanics, rendering, feel, and monetization behavior.
- Out of scope: App Store submission operations (use `app-store-release`).
- Required handoff fields: `Scope`, `Changes`, `Validation`, `Open Issues`.

## Workflow

1. Confirm game mode and scene architecture before edits (`arcade`, `scroller`, `tile`, `isometric`).
2. Implement gameplay logic separately from rendering where possible.
3. Add or tune animation/effects and haptics for player feedback.
4. Validate monetization paths (IAP/ads) in test-safe configurations.
5. Run performance and gameplay QA gates on simulator and at least one physical iPhone.

## Native Stack Defaults

- Gameplay/rendering: `SpriteKit`
- State/pathfinding/rules helpers: `GameplayKit`
- Haptics: `Core Haptics`
- Purchases: `StoreKit 2`
- Ads: mediated SDK selected per project policy

## 2D Genre Guidance

- Tile/map and side scrollers: prefer `SKTileMapNode` + explicit collision layers.
- Isometric with shallow terrain depth: keep one-step height metadata per tile and deterministic z-ordering.
- Effects: use sprite atlases, particle systems, and shader-based accents sparingly to preserve frame time.

## Validation Gates

- Frame pacing stable on representative gameplay loops.
- Gameplay logic tests pass for scoring, state transitions, and failure conditions.
- Haptics degrade gracefully on unsupported devices.
- IAP and ad flows do not block core gameplay loops when unavailable.

## References

Load only what is needed:
- Gameplay architecture and 2D scene patterns: `references/gameplay-and-scenes.md`
- Animation, haptics, and feel tuning: `references/animation-haptics.md`
- IAP/ads integration and game QA checklist: `references/monetization-and-qa.md`

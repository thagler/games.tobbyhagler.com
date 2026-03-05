# Monetization and QA (iOS Games)

## In-App Purchases

- Use StoreKit 2 APIs and local StoreKit configuration for development.
- Validate entitlement, restore, and offline/failed purchase behavior.
- Keep game loop responsive if purchase flows fail or are unavailable.

## Ads

- Isolate ad SDK integration behind an internal adapter.
- Make ad availability non-blocking for gameplay continuity.
- Validate ad error and no-fill cases explicitly.

## Game QA Gate

- Gameplay logic tests for score, progression, failure, and retries.
- Frame-time checks on representative scenes.
- Input checks for touch edge cases and interruption handling.
- Monetization checks for purchase success/failure and ad fallback behavior.

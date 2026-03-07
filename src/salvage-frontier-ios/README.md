# Salvage Frontier iOS Prototype

This directory contains the active native iOS prototype for Salvage Frontier.

## Project layout

- `SalvageFrontier.xcodeproj` Xcode project
- `SalvageFrontier/App/` SwiftUI app entry
- `SalvageFrontier/Views/` SpriteKit host views
- `SalvageFrontier/Scenes/` transit combat-feel prototype scene
- `SalvageFrontier/Systems/` prototype configs and lightweight game definitions

## Current prototype slice

- hybrid lane-readable ship movement with light tilt
- auto-fire player weapon baseline
- lane-based breach risk and hull feedback
- definition-driven enemy spawning with target dummies plus one Scout enemy
- simple continuous encounter respawn loop

## Build and run (CLI)

```bash
xcodebuild -project SalvageFrontier.xcodeproj \
  -scheme SalvageFrontier \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/sf-derived build

xcrun simctl boot 'iPhone 16e' || true
xcrun simctl bootstatus 'iPhone 16e' -b
xcrun simctl install 'iPhone 16e' /tmp/sf-derived/Build/Products/Debug-iphonesimulator/SalvageFrontier.app
xcrun simctl launch 'iPhone 16e' com.tobbyhagler.salvagefrontier
```

## Build and run (Xcode)

1. Open `SalvageFrontier.xcodeproj`.
2. Select scheme `SalvageFrontier`.
3. Choose an iOS simulator (for example `iPhone 16e`).
4. Run.

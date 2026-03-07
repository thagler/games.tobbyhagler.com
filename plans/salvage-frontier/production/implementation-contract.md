# Implementation Contract

## Language
- Swift (current stable Xcode-supported version)

## Engine / Framework
- SpriteKit for gameplay scenes and simulation
- SwiftUI for lightweight shell/HUD wrappers where needed

## Code Location
- Project root for implementation: `src/salvage-frontier-ios/`
- Expected Xcode project path: `src/salvage-frontier-ios/SalvageFrontier.xcodeproj`

## Build / Run
From repo root:

```bash
xcodebuild -project src/salvage-frontier-ios/SalvageFrontier.xcodeproj -scheme SalvageFrontier -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Run in Simulator:
- Open `src/salvage-frontier-ios/SalvageFrontier.xcodeproj` in Xcode
- Select scheme `SalvageFrontier`
- Select target simulator `iPhone 16`
- Press Run

## Simulator / Device Target
- Primary development target: iOS Simulator, `iPhone 16`
- Optional validation target: modern physical iPhone on latest stable iOS

# iOS Skill Contract Matrix

## Native Path (Current)

| Skill | Purpose | Dependencies | Triggers | Scope | Outputs | Validation Gates |
| --- | --- | --- | --- | --- | --- | --- |
| `ios-app-dev` | Build and QA native iOS app features locally | none | Swift/SwiftUI/UIKit feature work, simulator/device testing, XCTest/Swift Testing, profiling | Architecture, implementation, local test/QA workflows | Code changes, test/profiling results, handoff summary | Build pass, affected tests pass, critical flow UI checks pass, no critical perf regressions |
| `ios-game-dev` | Build and QA native iOS game features | `ios-app-dev` | SpriteKit/GameplayKit gameplay work, tile/scroller/isometric scenes, haptics, IAP/ads integration | Gameplay logic, scene systems, feel/perf tuning, monetization behavior | Code and content changes, gameplay/perf checks, handoff summary | Stable frame pacing in target scenes, gameplay tests pass, haptics fallback verified, IAP/ad failure paths safe |
| `app-store-release` | Submit and operate App Store/TestFlight releases | none | Build submission, metadata/privacy setup, TestFlight, review handling | Release preparation, App Store Connect operations, compliance checks | Release checklist status, submission state, review notes | Release checklist complete, policy/compliance checks complete, submission state tracked |

## Deferred Path (Later)

If you later add cross-platform engines, define separate engine-specific skills (`unity-game-dev`, `godot-game-dev`) instead of expanding native skills beyond clarity.

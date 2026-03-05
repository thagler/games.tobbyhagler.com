---
name: ios-app-dev
description: Build and validate native iOS applications on macOS using Xcode, Swift, UIKit/SwiftUI, simulator and device testing, and CI-ready quality gates. Use when tasks involve iOS app architecture, feature implementation, local debugging, XCTest or Swift Testing, xcodebuild workflows, simulator/device QA, performance profiling, or pre-release readiness checks.
---

# iOS App Dev

Use this skill to implement and verify native iOS app functionality with reproducible local workflows.

## Dependencies

- none

## Contract

- Scope: native iOS app development and QA on macOS.
- Out of scope: App Store submission operations (use `app-store-release`).
- Required handoff fields: `Scope`, `Changes`, `Validation`, `Open Issues`.

## Workflow

1. Confirm project constraints: Xcode version, deployment target, bundle ID, signing method, simulator matrix.
2. Plan changes and identify touched targets/schemes before editing.
3. Implement feature work in small commits with testable seams.
4. Run local validation (`build`, `tests`, targeted UI checks, profiling as needed).
5. Summarize results with commands run, destinations used, and unresolved risks.

## Validation Gates

- Build passes for active scheme and debug configuration.
- Unit tests pass for affected modules.
- UI tests pass for changed user-critical flows.
- No new critical crash or memory regressions from local profiling.

## Command Baseline

- Build: `xcodebuild -scheme <Scheme> -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Test: `xcodebuild -scheme <Scheme> -destination 'platform=iOS Simulator,name=iPhone 16' test`
- Device list: `xcrun simctl list devices`
- Profile run (example): `xctrace record --template 'Time Profiler' --launch -- <AppBinaryOrCommand>`

## References

Load only what is needed:
- Local commands and simulator/device flow: `references/local-dev-and-testing.md`
- QA and review checklist: `references/qa-and-review.md`

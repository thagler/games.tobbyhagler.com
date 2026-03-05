# Local Dev and Testing (iOS App)

## Local Loop

1. Run in Simulator for fast iteration.
2. Re-run changed paths on physical device for hardware-dependent behavior (camera, sensors, haptics, thermal, background behavior).
3. Keep destinations explicit in commands and reports.

## Command Patterns

- List simulators: `xcrun simctl list devices`
- Boot simulator: `xcrun simctl boot '<Simulator Name>'`
- Build: `xcodebuild -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Simulator Name>' build`
- Test: `xcodebuild -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Simulator Name>' test`

## Test Layering

- Logic/domain checks: Swift Testing or XCTest unit tests.
- Integration checks: target-level tests around storage/networking boundaries.
- User-critical flows: XCUI tests for login, purchase entry points, settings, and failure states.

## Profiling

Use Instruments/xctrace for time, memory, and launch profiling on representative flows before release candidates.

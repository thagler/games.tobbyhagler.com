# 0006 Launch And Loop

## Objective
Close the full loop by enabling launch and route selection for next run.

## Why
This validates loop completion and replayability by transitioning from outpost success/failure into route-based next-run choice.

## Requirements
- enable launch action once fuel requirement is met
- present exactly three route options after launch
- apply a simple route modifier to the next loop instance

## Constraints
- exactly three route options in prototype
- modifiers should be simple and testable

## Acceptance Criteria
- player can launch when conditions are met
- route selection appears after launch
- chosen route affects next loop

## Non-Goals
- deep route graph
- narrative events system

## Test Steps
1. Reach launch threshold and launch.
2. Select a route.
3. Start next loop and verify route modifier applied.

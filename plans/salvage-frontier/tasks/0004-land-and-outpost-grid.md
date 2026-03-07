# 0004 Land And Outpost Grid

## Objective
Create landing transition and load a basic outpost map with buildable space.

## Why
This task links transit combat to the outpost phase, proving the loop transition from combat into extraction/build decisions.

## Requirements
- implement a landing trigger from transit into outpost phase
- load a minimal outpost map with valid buildable area
- display resource nodes needed for extraction choices

## Constraints
- keep outpost map small and simple
- do not add extra systems beyond transition + placement foundation

## Acceptance Criteria
- landing trigger moves player into outpost phase
- outpost map loads consistently
- resource nodes are visible
- basic build placement works

## Non-Goals
- advanced UI
- late-game structure variety

## Test Steps
1. Complete transit trigger condition.
2. Verify outpost scene loads.
3. Place at least one structure on valid tile.

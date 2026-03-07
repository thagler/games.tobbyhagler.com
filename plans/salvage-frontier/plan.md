# Salvage Frontier Plan

## Goal
Build and validate the smallest playable loop for an iOS hybrid game that alternates between transit combat and temporary outpost defense/extraction.

Core loop target:
`transit -> land -> extract/defend -> refuel -> launch -> choose next route`

## Current Milestone
Milestone 1: Project Bootstrap

## Definition Of Done (Prototype)
- Transit phase is readable and satisfying.
- Landing transitions cleanly into a basic outpost phase.
- Player gathers salvage, builds minimal defenses, and can refuel.
- Player can launch and complete one full loop.

## Scope
### In Scope
- 1 player ship with bounded movement and auto-fire
- 3 enemy types
- Salvage + fuel
- 3 structures: turret, wall, extractor/refinery
- 2 to 4 outpost waves
- 3 route choices between runs

### Out Of Scope
- deep research tree
- multiple ship classes
- broad content variety
- elaborate story
- polished art pipeline
- wide balancing passes

## Top Risks
- Transit and outpost phases may feel disconnected.
- Outpost pacing may become too slow or too hectic.
- Resource/fuel economy may fail to create meaningful decisions.

## Next 3 Tasks
1. `tasks/0001-bootstrap-project.md`
2. `tasks/0002-player-ship-prototype.md`
3. `tasks/0003-enemy-wave-prototype.md`

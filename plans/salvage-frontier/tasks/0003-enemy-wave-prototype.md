# 0003 Enemy Wave Prototype

## Objective
Add enemy spawning, collisions, and salvage drops in transit.

## Why
Enemy pressure plus salvage gain establishes the risk/reward foundation that feeds outpost extraction, defense choices, and refuel progression.

## Requirements
- spawn enemies in discrete waves during transit
- resolve player/enemy collisions and damage outcomes
- award salvage drops from defeated enemies with pickup behavior

## Constraints
- keep to three enemy archetypes max
- tune for readability over difficulty

## Acceptance Criteria
- enemies spawn in waves
- collisions and damage resolve
- defeated enemies can drop salvage

## Non-Goals
- advanced enemy AI
- final balance

## Test Steps
1. Start transit scene.
2. Observe at least one complete wave.
3. Confirm salvage drops and pickup flow.

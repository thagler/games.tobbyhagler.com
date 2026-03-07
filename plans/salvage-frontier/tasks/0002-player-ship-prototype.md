# 0002 Player Ship Prototype

## Objective
Implement player ship movement and auto-fire behavior for transit phase.

## Why
Transit combat is the first step of the canonical loop; readable movement and firing are mandatory before enemy and resource systems can be validated.

## Requirements
- implement bounded horizontal or lane-based ship movement
- implement auto-fire with stable cadence
- expose basic hit/damage integration points for later enemy work

## Constraints
- bounded movement only
- keep controls readable and forgiving

## Acceptance Criteria
- player moves consistently in transit bounds
- auto-fire triggers at expected cadence
- basic hit/damage hooks are available

## Non-Goals
- ship variants
- advanced weapon systems

## Test Steps
1. Start transit scene.
2. Move ship across full allowed bounds.
3. Confirm auto-fire and shot cadence.

# Core Patterns

Use these as the default development workflow toolkit.

## 1) Orchestrator-Worker
- One orchestrator decomposes work and merges results.
- Default control model for multi-agent tasks.

## 2) Blackboard (File-Based State)
- Agents coordinate through shared files, not direct memory.
- Use project-local artifacts as durable state.

## 3) Checkpoint-Resume
- Sequential handoff when context is exhausted and work is not splittable.
- Pair with compact checkpoint summaries.

## 4) Plan-Execute
- Separate planning from execution.
- Place human approval gate between phases.

## 5) Nested Orchestrators
- Use when a sub-problem needs local decomposition and coordination.

## 6) Pipeline
- Stage-by-stage outputs with strict input/output contracts.
- Best for extraction -> architecture -> specification -> decomposition flows.

## 7) Map-Reduce
- Split into independent chunks and run in parallel.
- Merge with deterministic ordering and schema checks.

## 8) Reflexion
- Validate, reflect, and retry against explicit quality criteria.
- Use only when measurable checks exist.

## Selection Heuristic
- Sequential dependency chain: `Pipeline`
- Independent chunkable work: `Map-Reduce`
- Long unsplittable task: `Checkpoint-Resume`
- High validation burden: `Reflexion`
- Complex delegated domain: `Nested Orchestrators`

## Recommended Base Stack
`Plan-Execute + Orchestrator-Worker + Blackboard`, then add `Pipeline/Map-Reduce/Reflexion` as needed.

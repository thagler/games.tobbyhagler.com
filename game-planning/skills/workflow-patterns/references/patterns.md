# Orchestration Pattern Reference

## Pattern Set

- `Orchestrator-Worker`: default top-level control model.
- `Plan-Execute`: separate planning artifact from implementation pass.
- `Pipeline`: stage-by-stage transformation with strict input/output contracts.
- `Map-Reduce`: split independent work, run in parallel, merge by stable order.
- `Checkpoint-Resume`: continue interrupted sequential work from compact checkpoint summaries.
- `Reflexion`: validate, reflect, retry with bounded attempts.
- `Blackboard`: coordinate stateless workers through shared files.

## Decision Matrix

Use this quick rule set:
- Need human or gate review before coding -> `Plan-Execute`
- Steps are sequential and artifact-driven -> `Pipeline`
- Subtasks are independent and homogeneous -> `Map-Reduce`
- Task cannot be parallelized and exceeds one context window -> `Checkpoint-Resume`
- Objective pass/fail validation exists -> add `Reflexion`
- Multiple workers need shared state without chat history coupling -> add `Blackboard`

## Recommended Contracts

- Stage contract fields: `inputs`, `outputs`, `acceptance_checks`, `owner`.
- Handoff summary fields: `Scope`, `Changes`, `Validation`, `Open Issues`.
- Map-reduce merge contract: define chunk IDs, output filenames, and deterministic merge order before execution.

## Guardrails

- Prefer `Map-Reduce` over `Checkpoint-Resume` when both are possible.
- Keep status summaries under 1K tokens and completion summaries under 2K tokens.
- Scope each invocation to specific files/sections; avoid broad "continue" prompts.
- Cap reflexion retries (recommended: 2) before escalation.

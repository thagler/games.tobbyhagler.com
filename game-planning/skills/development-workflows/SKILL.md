---
name: development-workflows
description: Design and run multi-agent software development workflows using orchestration patterns, explicit handoff contracts, quality gates, and context-efficiency controls. Use when planning or executing complex work across multiple agents/sessions, including roadmap-to-tickets pipelines and parallelized implementation streams.
---

# Development Workflows

## Dependencies
- workflow-patterns

## Use This Skill When
- You need to design or run a multi-agent development workflow end to end.
- A task should be split into planning, execution, validation, and synthesis phases.
- You need explicit orchestration choices (pipeline, map-reduce, checkpoint-resume).
- You need to reduce context-window waste across agent handoffs.
- You need repeatable handoff contracts and escalation rules.

## Default Operating Model
1. Start with `Plan-Execute` and require human approval before implementation.
2. Use `Orchestrator-Worker` as control structure.
3. Persist shared state via `Blackboard` files.
4. Use `Pipeline` for sequential stages.
5. Prefer `Map-Reduce` for independent work chunks.
6. Use `Checkpoint-Resume` only when the task cannot be split.
7. Add `Reflexion` where automated validators exist.

## Workflow Contract
Define these artifacts up front and keep them small:
- `plan.md`: objective, scope, constraints, acceptance criteria, selected patterns.
- `status.md`: done, remaining, blockers, file pointers (target under 1K tokens).
- `checkpoint-summary.md`: what was done, what remains, exact next reads (target under 2K tokens).
- `merge-notes.md`: deterministic merge order and conflict rules for map-reduce outputs.

Each worker handoff must include:
- `Scope`
- `Changes`
- `Validation`
- `Open Issues`

## Pattern Selection Rules
- Use `Pipeline` when each stage depends on prior stage output.
- Use `Map-Reduce` when work can be split into independent equal-shape chunks.
- Use `Nested Orchestrators` when one sub-domain requires its own local coordination.
- Use `Checkpoint-Resume` only for long sequential work with unavoidable dependencies.
- Use `Reflexion` only when pass/fail checks are available.

## Execution Steps
1. Classify task shape: sequential, parallel, hierarchical, or validation-heavy.
2. Select pattern set and define artifact contracts.
3. Launch workers with narrowly scoped read/write instructions.
4. Enforce validation gates (`test`, `lint`, schema checks, rubric checks).
5. Merge outputs deterministically.
6. Produce final synthesis with unresolved risks and next actions.

## Context-Efficiency Rules
- Never hand off with “continue the work.” Always specify exact file sections and output required.
- Prefer selective reads (offset/limit/section-level) over whole-file reads.
- Maintain a lightweight index for source-of-truth file locations.
- Replace broad checkpoint transfers with map-reduce whenever task decomposition is feasible.

## Escalation Rules (HITL)
Escalate to human review when any trigger is hit:
- Confidence is low between viable alternatives.
- Action crosses a policy/risk boundary.
- Budget/time/token threshold is exceeded.
- Validation fails twice in a row.
- Requirements remain ambiguous after one clarification pass.

## Guardrails
- Restrict worker write scope to assigned paths.
- Require idempotent operations where retries are likely.
- Block secrets/PII in generated artifacts.
- Track ownership of files touched by each worker to avoid collision.

## References
Read only what you need:
- Core pattern definitions and usage guidance: `references/core-patterns.md`
- Context tax, handoff efficiency, and orchestration economics: `references/workflow-economics.md`
- Additional patterns and cross-cutting controls: `references/extended-patterns.md`

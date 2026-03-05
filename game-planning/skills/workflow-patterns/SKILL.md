---
name: workflow-patterns
description: Choose and apply orchestration patterns for multi-step coding work in Codex. Use when tasks require delegation, parallel decomposition, context-window control, staged execution, checkpoint handoffs, or quality-gated retries. Trigger for requests about orchestrator/sub-agent behavior, blackboard coordination, plan/execute contracts, pipeline stage design, map-reduce splitting, and reflexion loops.
---

# Workflow Patterns

Use this skill to select a minimal orchestration pattern set, define handoff contracts, and keep context usage bounded.

## Quick Selection

1. Use `Plan-Execute` when a reviewable plan should be approved before implementation.
2. Use `Pipeline` when work is sequential and each stage has a clear artifact contract.
3. Use `Map-Reduce` when work can be split into independent chunks and merged deterministically.
4. Use `Checkpoint-Resume` only when work is sequential and cannot be split.
5. Use `Reflexion` when an automated validator can gate retries (`test`, `lint`, `a11y`, schema checks).
6. Use `Blackboard` for stateless sub-agent coordination through project-local files.
7. Use `Orchestrator-Worker` as the default control structure.

## Execution Rules

- Keep orchestrator context small: store decisions, file pointers, and merged summaries only.
- Require each sub-agent handoff to include `Scope`, `Changes`, `Validation`, and `Open Issues`.
- Prefer cheaper agents for bounded edits and stronger agents for architecture/debugging ambiguity.
- Parallelize only disjoint file ownership; serialize overlapping edits.
- Enforce deterministic merge order for map-reduce outputs.

## References

Load only what is needed:
- Pattern details and decision matrix: `references/patterns.md`
- Blackboard file contract and status schema: `references/blackboard.md`

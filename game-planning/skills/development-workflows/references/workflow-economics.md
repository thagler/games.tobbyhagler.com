# Workflow Economics

## Context Window Tax
Replacement agents lose effective capacity because they must re-read prior artifacts.

Typical failure modes:
- Re-reading large documents repeatedly.
- Re-reading the same setup files across agent hops.
- Handing off without summaries or read scopes.
- Re-running exploratory search already completed.

## Reduction Strategies
1. Write `checkpoint-summary.md` with:
   - what is complete
   - what remains
   - exact files/sections to read next
2. Scope reads:
   - read only the needed sections, not whole files.
3. Maintain an index:
   - keep a compact file map for rapid lookup.
4. Scope handoff prompts:
   - specify exact ranges/artifacts and expected output.
5. Prefer map-reduce over checkpoint-resume:
   - avoid repeated re-read overhead.
6. Add reflexion loops for validator-driven tasks:
   - reduce orchestration rework cycles.

## Practical Thresholds
- `status.md`: target under 1K tokens.
- `checkpoint-summary.md`: target under 2K tokens.
- Escalate when repeated handoffs consume more effort than decomposing the task.

## Handoff Template
- `Scope`: assigned sub-problem and boundaries.
- `Changes`: files/artifacts created or modified.
- `Validation`: checks executed and outcomes.
- `Open Issues`: blockers, assumptions, and required follow-ups.

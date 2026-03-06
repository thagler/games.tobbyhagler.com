# Extended Patterns

Use these when the core 8 patterns are insufficient.

## Router
- Classify incoming task and route to one specialist.
- Use when task belongs to one domain, not multiple collaborating domains.

## Evaluator-Optimizer
- Separate generator and judge roles with structured critique loops.
- Use when quality rubric is explicit and revisions are expected.

## Swarm / Peer Handoff
- Agents pass control laterally with full context transfer.
- Use for specialist chains without central micromanagement.

## Voting / Consensus
- Multiple agents solve same problem independently; merge by agreement.
- Use for high-stakes decisions where confidence is more important than token cost.

## Human-in-the-Loop (Cross-Cutting)
Define explicit escalation triggers:
- low confidence,
- high cost/risk action,
- policy boundary,
- unresolved ambiguity,
- repeated validation failure.

## Guardrails (Cross-Cutting)
Apply pre-action checks:
- file-scope limits,
- token/time budgets,
- tool restrictions,
- secret/PII filters,
- idempotency safeguards.

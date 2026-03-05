# Blackboard Pattern (File-Based Coordination)

Use a temporary, project-local blackboard to coordinate stateless and headless sub-agent invocations while preventing orchestrator context overload.

## Location

- Blackboard root: `docs/.blackboard/` (must be gitignored).
- Keep `docs/` tracked in Git.

## File Contract

For each task ID `TASK-<id>`:
- `docs/.blackboard/TASK-<id>.md`: goal, constraints, acceptance criteria, owner.
- `docs/.blackboard/TASK-<id>.status.jsonl`: append-only progress events.
- `docs/.blackboard/TASK-<id>.summary.md`: final condensed handoff.

Optional shared index:
- `docs/.blackboard/INDEX.md`: active tasks, owners, and file pointers.

## Status Event Schema

Each JSONL event should include:
- `timestamp`
- `agent_id`
- `task_id`
- `step`
- `status` (`queued|running|blocked|completed|failed`)
- `artifacts` (file paths)
- `next_action`

## Operating Rules

- Return only short status + file paths to orchestrator; do not return full transcripts.
- Read summaries first; read raw artifacts only when required.
- Clean up stale task files after completion.
- If parallel workers touch overlapping files, serialize and update task ownership in `TASK-<id>.md`.

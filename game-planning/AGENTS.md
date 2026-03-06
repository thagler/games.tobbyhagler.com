# Repository Guidelines

## Project Structure & Module Organization
This repo has two concerns: a showcase site and shared game-planning assets.

- `src/` showcase application code (UI modules, shared client utilities)
- `public/` showcase static assets (images, audio, icons)
- `tests/` automated tests mirroring `src/` paths
- `games/` published playable game builds and static prototypes
- `game-planning/` reusable multi-game planning + orchestration material
- `game-planning/docs/` planning docs, ADRs, and local orchestration state in `game-planning/docs/.blackboard/` (gitignored)
- `game-planning/skills/` reusable local skills and references used across game projects

Group files by feature first (example: `src/showcase/game-cards/` or `games/space-runner/`).

## Build, Test, and Development Commands
Tooling is not fully defined yet. Use lightweight local commands until scripts are added:
- `python3 -m http.server 8080` - run a local static server from repo root
- `npx serve .` - alternative static server for Node-based workflows
- `npm run dev` - expected future dev server entrypoint
- `npm test` - expected future test command

When introducing tooling, add `dev`, `build`, `test`, and `lint` scripts in `package.json` and update this file in the same PR.

## Coding Style & Naming Conventions
- Indentation: 2 spaces (HTML, CSS, JS, JSON).
- File names: kebab-case (`pause-menu.js`, `game-hud.css`).
- JS/TS: `camelCase` for values/functions, `PascalCase` for classes/types.
- Keep modules focused and small; avoid mixed concerns in one file.

If ESLint/Prettier are configured, run them before opening a PR.

## Testing Guidelines
- Put tests under `tests/` using mirrored feature paths.
- Use `*.test.js` or `*.spec.js` naming.
- Cover at least one happy path and one edge case per new behavior.
- For gameplay logic, prefer deterministic tests for state updates and scoring rules.

## Commit & Pull Request Guidelines
Use Conventional Commits:
- `feat: add endless mode timer`
- `fix: prevent double score submission`
- `docs: clarify local setup`

PRs should include:
- what changed and why
- linked issue/task (if available)
- screenshots or GIFs for UI/gameplay changes
- test evidence (automated and manual)

## Agent Orchestration Rules
Treat the primary agent as an orchestrator, not an all-in-one executor.

- Delegate by default: split work into focused sub-tasks (implementation, tests, docs, review).
- Keep orchestrator context lean: store only task summary, decisions, and final diffs; avoid replaying full logs.
- Require compact handoffs from sub-agents with `Scope`, `Changes`, `Validation`, and `Open Issues`.
- Prefer cheaper/faster sub-agents for bounded edits; reserve high-reasoning agents for architecture, debugging, and ambiguous tasks.
- Run sub-agents in parallel only when file ownership is disjoint; serialize when touching overlapping files.
- After each sub-task, merge results into a concise orchestrator checkpoint (5-10 bullets max).

### Workflow Patterns Skill
For orchestration design details, load `workflow-patterns` at `game-planning/skills/workflow-patterns/SKILL.md`.

Pattern names used in this repository:
- `Orchestrator-Worker`
- `Plan-Execute`
- `Pipeline`
- `Map-Reduce`
- `Checkpoint-Resume`
- `Reflexion`
- `Blackboard`

Use the skill references for contracts and procedures:
- `game-planning/skills/workflow-patterns/references/patterns.md`
- `game-planning/skills/workflow-patterns/references/blackboard.md`

### Skill Loading Policy
Sub-agents must load only the skills required for their scope.

- Skill dependencies are mandatory. If a selected skill declares parent dependencies, load all parents first.
- Declare dependencies in the skill body (not YAML frontmatter) using a top-level section, for example: `## Dependencies` then `- ios-app-dev`.
- Keep dependency declarations near the top of `SKILL.md` so they are read early.
- Phaser + Vite game work: load the Phaser/Vite skill before editing gameplay, scene lifecycle, or build config.
- Native iOS app implementation/testing work: load `ios-app-dev`.
- Native iOS game work: load `ios-game-dev` (which depends on `ios-app-dev`).
- App Store Connect submission/release operations: load `app-store-release`.
- Tooling/setup work: load install/config skills relevant to package manager and bundler.
- Orchestration-heavy work: load `workflow-patterns` for pattern selection and handoff contracts.
- End-to-end development workflow design or optimization work: load `development-workflows` (and its dependency `workflow-patterns`).
- Generic docs/refactor work: do not load heavy implementation skills unless code changes require them.

Always include the selected skill(s) in the handoff summary.

## Security & Configuration Tips
Do not commit secrets, tokens, or `.env` files. Keep local configuration in ignored files and document required environment variables in `README.md`.

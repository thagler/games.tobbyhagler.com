# QA and Review Checklist (iOS App)

## Definition of Done

- Feature behavior matches acceptance criteria.
- Build and affected tests pass.
- Error and empty states are handled.
- Accessibility labels/roles are present for changed UI.
- Telemetry/crash visibility is maintained.

## Review Focus

- Architecture boundaries remain clear (UI, domain, persistence/network).
- Concurrency and async cancellation paths are safe.
- No new hardcoded secrets, keys, or production endpoints in source.
- Migration/risk notes included for schema or API changes.

## Report Format

Use this handoff format:
- `Scope`
- `Changes`
- `Validation`
- `Open Issues`

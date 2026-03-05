---
name: app-store-release
description: Prepare and execute iOS app and game releases through App Store Connect, including TestFlight, review readiness, compliance checks, and rollout operations. Use when tasks involve release metadata, pricing/availability, privacy declarations, in-app purchase submission state, build upload, beta testing coordination, or App Review responses.
---

# App Store Release

Use this skill for release operations after implementation and QA are complete.

## Dependencies

- none

## Contract

- Scope: App Store Connect release workflow for iOS apps/games.
- Out of scope: core feature implementation and gameplay coding.
- Required handoff fields: `Scope`, `Changes`, `Validation`, `Open Issues`.

## Workflow

1. Verify release prerequisites (build health, tests, metadata completeness, compliance items).
2. Prepare archive/upload flow and confirm build processing status.
3. Configure App Store Connect records (version, pricing, availability, privacy, age/content data).
4. Validate TestFlight readiness for internal/external cohorts.
5. Submit for review with explicit release strategy (`manual`, `automatic`, or phased release).
6. Monitor review outcomes and process corrective updates.

## Compliance Guardrails

- Re-check Apple upcoming requirements before each release cycle.
- Confirm digital goods monetization paths use allowed in-app purchase policies.
- Confirm third-party SDK privacy-manifest/signature requirements for included SDKs.
- Ensure required privacy disclosures and permissions text are accurate.

## References

Load only what is needed:
- Release checklist and submission sequence: `references/release-checklist.md`
- Compliance and policy watchlist: `references/compliance-watchlist.md`

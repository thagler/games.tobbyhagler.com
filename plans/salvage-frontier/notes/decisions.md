# Design Decisions

| Date | Decision | Rationale | Impact |
|---|---|---|---|
| 2026-03-06 | Initial prototype scope limited to one full loop | Prove core fun before expansion | Prevents early feature creep |
| 2026-03-06 | Use placeholder transit test constants (`shipSpeed`, `autoFireInterval`, `bulletSpeed`) during Task 0001 | Needed to validate basic movement/shooting test space without tuning pass | Values must be revisited in Milestone 2 tuning |
| 2026-03-06 | Treat iOS build/run validation as pending local Xcode availability | Current environment lacks full Xcode (`xcodebuild` unavailable) | Bootstrap code and structure prepared; build verification deferred |

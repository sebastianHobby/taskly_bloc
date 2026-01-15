# Phase 02 — Domain coverage uplift (highest ROI)

Created at: 2026-01-14T07:44:19Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions (required)

- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by the end of the phase.
- Review `doc/architecture/` before implementing and keep architecture docs updated if this phase changes architecture.
- During the phase: focus on writing tests that compile; avoid repeatedly running test/coverage commands while scaffolding.
- End of phase: run **exactly one** test or coverage command to validate.

## End-of-phase verification (run once)

Recommended command (domain-focused, still fast):

- `flutter test --preset=fast test/domain/`

## Intent

Raise overall coverage efficiently by focusing on:
- pure domain services
- rule evaluation
- mappers/validators
- state machines that do not require Flutter rendering

This phase should deliver the largest coverage gains per unit effort.

## Target

- Bring `lib/domain` filtered coverage from ~49.5% to **≥ 85%**.
- Raise overall filtered coverage materially (expect +10–25 points, depending on gaps).

## Worklist (repeatable playbook)

For each chosen domain unit (service/use-case):

1) Identify public behavior and invariants
- input validation
- idempotency / stability
- ordering guarantees
- “no surprise side effects”

2) Add tests for:
- happy path
- not-found path
- error path
- boundary conditions
- time-based behavior (using `TestClock`)

3) Prefer fakes over mocks where possible
- keep tests fast and hermetic
- reduce stubbing complexity

## Selection strategy

Start with the biggest/riskiest logic units:
- allocation & attention systems (core business value)
- any domain rule engines
- mapping/normalization logic that affects persistence and UI

Use coverage reports to prioritize:
- lowest-covered files with high LF (line count)
- files frequently touched by development

## Acceptance criteria

- `lib/domain` reaches the target threshold.
- Domain tests remain fast and deterministic.
- New tests follow the safe wrapper + deterministic time conventions.

## Risk & mitigation

- Risk: chasing coverage leads to low-value tests.
  - Mitigation: test behavior/invariants, not getters/freezed models.

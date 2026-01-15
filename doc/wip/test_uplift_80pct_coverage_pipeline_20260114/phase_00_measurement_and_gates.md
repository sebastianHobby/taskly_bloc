# Phase 00 — Measurement, suite entrypoints, and coverage gates

Created at: 2026-01-14T07:44:19Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions (required)

- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by the end of the phase.
- Review `doc/architecture/` before implementing and keep architecture docs updated if this phase changes architecture.

## Intent

Make test execution and coverage measurement unambiguous and repeatable so the rest of the uplift is frictionless.

This phase should be minimal-risk: mostly tooling/docs and small guardrails.

## Status

Completed (already implemented in the repo).

## What’s in place now

- Official metric: `coverage/lcov_filtered.info` generated from `coverage/lcov.info` using `tool/coverage_filter.dart`.
- Coverage reporting: `tool/coverage_summary.dart` and VS Code tasks (`coverage_filter`, `coverage_summary`).
- Canonical suite selection: presets documented in `test/README.md` and defined in `dart_test.yaml`.
- Hook gate ramp: staged coverage gates in `git_hooks.dart` (filtered LCOV).

## Risks & mitigations

- Risk: changing hook gates causes friction.
  - Mitigation: introduce ramp immediately and document it clearly.

- Risk: filtered coverage hides real gaps if filter grows too broad.
  - Mitigation: only exclude files with clear justification; keep exclusions reviewed.

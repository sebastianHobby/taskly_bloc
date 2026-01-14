# full_ed_rd_core_migration — Phase 05: Verification + documentation

Created at: 2026-01-14 (UTC)
Last updated at: 2026-01-14 (UTC)

## Goal
Run final verification (analyze + a single recorded test run) and update docs so
architecture and contracts match the implemented behavior.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- In this final phase: fix **any** `flutter analyze` error or warning (even if
  unrelated).
- Run tests once at the end using the recorded runner task `flutter_test_record`.
  - If it exits with code 42, do not retry; document why tests weren’t run.

## Verification steps

### 05.1 Analyze
- Run `flutter analyze` and ensure it is clean.

### 05.2 Tests (recorded)
- Run VS Code task `flutter_test_record` (preferred).
- Confirm artifacts exist under `build_out/test_runs/<timestamp>/`.

### 05.3 Documentation updates
Update docs to reflect the final contracts:
- `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md`
  - Ensure routing section reflects NAV-01 routes + `/task/:id` redirect.
  - Ensure entity route flow reflects route-backed editor pages.
- `doc/backlog/editor_detail_template_contracts_formbuilder.md`
  - Update the “current implementation status (snapshot)” to reflect the new
    aligned state.

## Acceptance criteria
- Analyze clean.
- Exactly one recorded test run executed (or explicitly skipped due to code 42).
- Docs match implemented behavior and decisions.

## Notes
- Avoid “extra refactors” here; only correctness/documentation and analyzer
  cleanup.

# Taskly â€” Copilot Instructions

You are an expert in Flutter and Dart development.

## Response style

- Be concise and actionable.
- Avoid narrating routine steps unless blocked or asked.
- Summarize only when code/files changed, trade-offs were made, or asked.

## Repo workflow (strict)

### Git safety

- Never run git commands (checkout/reset/revert/clean/commit/rebase, etc.)
  without explicit user confirmation.

### Architecture-first

Before any non-trivial change (more than a tiny local refactor) or when giving
design options:

- Read doc/architecture/README.md.
- Read doc/architecture/INVARIANTS.md and comply.
- Read only the additional relevant doc/architecture guides/specs for the area
  being changed (do not blanket-read the entire folder).

When changes affect architecture (new boundaries, responsibilities, data flow,
storage/sync behavior, cross-feature patterns), update the relevant files under
doc/architecture/ in the same PR.

Keep specifications and architecture documents under `doc/` up to date. When
introducing significant new features, update architecture docs and, if the
feature has sufficient complexity, create a new deep dive spec.

If a change would violate an invariant:

- Get explicit user confirmation.
- Add a documented exception under doc/architecture/exceptions/ before
  implementing.

- When you identify dead code that is not used or you makes changes which replace/depreacte existing code
always offer to delete / tidy up the unused legacy code (confirming it's not used first)

## Taskly implementation guardrails (strict)

- Follow the layering rules and boundaries in doc/architecture/INVARIANTS.md.
- Taskly is BLoC-only for application state.
  - Widgets/pages must not call repositories/services directly.
  - Widgets/pages must not subscribe to domain/data streams directly.
- Shared UI lives in packages/taskly_ui and must remain pure UI.
  - Governance and boundaries are defined in doc/architecture/INVARIANTS.md and
    doc/architecture/guides/TASKLY_UI_GOVERNANCE.md.

## UI/UX tasks

When asked to design UI/UX:
- Review UI documentation and code related to the area being changed.
- Review related screens for consistency.
- Ask clarifying questions about intended experience.
- Offer design options in batches of 3 (with ids, pros/cons, recommendation).
- Keep offering options until the user asks to implement.
- Call out if the change impacts more than one screen/area.
- For preset-driven UI, explicitly list which screens will be impacted by any
  preset updates. If a new preset is required, state clearly that you are
  creating a new preset.

## Tooling and quality

- Prefer PowerShell for filesystem operations when needed.
- Formatting: use the dart_format tool.
- Quick fixes: use the dart_fix tool when appropriate.

### Analyzer and tests

- Always run `dart analyze` (command line) after all changes are completed and
  ensure it is green before reporting done.
- Always keep all tests up to date when changing code, and always run the
  relevant tests after a change. Follow existing test patterns.
- When adding new features always add corresponding tests including unit tests and integration or E2E tests if appropiate. 
- When creating new tests, always run them and ensure they pass.
- After any significant change, run the appropriate regression tests and ensure  they pass.
- Do not try to “fix tests to make them pass” while the analyzer reports
  problems.
- If `dart analyze` fails to start due to sandbox restrictions (e.g. “windows
  sandbox: spawn setup refresh”), rerun it with escalated permissions.
- When implementing changes, do not run tests unless the user explicitly asks
  or it is required to unblock progress.

### E2E / pipeline tests (strict)

- Follow `doc/architecture/runbooks/LOCAL_E2E_STACK.md`.
- Start the local stack before running pipeline tests:
  - `powershell -File tool/e2e/Start-LocalE2EStack.ps1 -ResetDb`
- Run pipeline tests via the helper script (not direct `flutter test`):
  - `powershell -File tool/e2e/Run-LocalPipelineIntegrationTests.ps1 -ResetDb`
- If the script reports missing app tables, run `supabase db pull` (after
  linking/auth) and re-run the start script.

### Code generation

- If build_runner output is needed after changes, run build_runner.


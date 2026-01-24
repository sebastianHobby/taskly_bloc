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
- Do not try to “fix tests to make them pass” while the analyzer reports
  problems.
- If `dart analyze` fails to start due to sandbox restrictions (e.g. “windows
  sandbox: spawn setup refresh”), rerun it with escalated permissions.
- When implementing changes, always keep tests up to date adding new tests as needed and running relevant tests after any significant change.

### Code generation

- If build_runner output is needed after changes, run build_runner.


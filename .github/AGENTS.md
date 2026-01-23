# Taskly — Copilot Instructions

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

- Always run flutter analyze (command line) before working on failing tests.
- Do not try to “fix tests to make them pass” while flutter analyze reports
  problems.
- When implementing changes, do not run tests unless the user explicitly asks
  or it is required to unblock progress.

### Code generation

- If build_runner output is needed after changes, run build_runner.

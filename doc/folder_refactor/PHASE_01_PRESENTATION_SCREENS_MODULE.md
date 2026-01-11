# Phase 01 — Presentation: Create `presentation/screens` module (Approach B)

## Goal

Move the unified screens UI out of `lib/presentation/features/screens/**` into `lib/presentation/screens/**`.

This phase is intentionally first because it avoids codegen churn and immediately clarifies the screens system boundary in the UI layer.

## Moves (mechanical)

- Move:
  - `lib/presentation/features/screens/**`
    → `lib/presentation/screens/**`

- Within the moved folder, normalize the renderer layout to a templates subfolder:
  - `lib/presentation/screens/renderers/**`
    → `lib/presentation/screens/templates/renderers/**`

(If a file already encodes “template renderer” semantics, it belongs under `templates/`.)

## Import updates

Update imports across `lib/**` to the new presentation module paths.

Common patterns to rewrite:

- `package:taskly_bloc/presentation/features/screens/...`
  → `package:taskly_bloc/presentation/screens/...`

Update any central switchboard imports:

- `lib/presentation/widgets/section_widget.dart`
  - Update renderer imports to `presentation/screens/templates/renderers/*`.
  - Update any references to old screens pages if present.

## Analyze and fix (required at end of phase)

- Run `flutter analyze`.
- Fix all errors/warnings created by the move (imports, missing symbols, wrong paths).

## Do NOT do in this phase

- Do not run tests.
- Do not reorganize unrelated UI features under `lib/presentation/features/**`.

# USM Maintainability Refactor — Decisions & Scope

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Approved design decisions (must follow exactly)
- **USM-001**: Option **B** — dedicated Actions BLoC/Cubit (mutations live in presentation BLoC, not widgets).
- **USM-002**: Option **B + A** — renderer registry (presentation) + module interpreter registry (domain).
- **USM-003**: Option **A** — sealed `SectionVm` hierarchy (typed params/data per template).
- **USM-004**: Option **B** — section-level errors where possible; screen-level errors only for fatal cases.
- **USM-005**: Option **A** — value types for identity (screen keys, template IDs, persistence keys).

## Architecture constraints (non-negotiable)
- Presentation boundary: widgets/pages must not call repositories/domain services directly and must not own cross-layer stream subscriptions.
- Typed USM path uses:
  - `UnifiedScreenPageFromSpec` (presentation)
  - `ScreenSpecBloc` (presentation)
  - `ScreenSpecDataInterpreter` (domain)
  - template/section renderers (presentation)
- Prefer small, composable pieces and explicit registries.

## Scope
### In scope
- Typed USM system-screen rendering path (the one documented in [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](../../architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md)).
- Refactors that improve maintainability and the mental model without changing UX.

Primary code areas:
- `lib/domain/screens/runtime/*`
- `lib/domain/screens/templates/*`
- `lib/presentation/screens/*`
- `lib/presentation/widgets/section_widget.dart`
- `lib/core/di/dependency_injection.dart`

### Out of scope (explicit)
- The legacy/data-driven screen pipeline (`ScreenDefinition`, `ScreenDataInterpreter`, etc.).
  - Note: there are historical docs under `doc/phases/unified_screen_model/*` that refer to old paths and may no longer match current code layout.
- UI/UX redesign (no USM UI/UX changes).
- Major navigation changes.

## Repo realities / gotchas
- The typed USM path DI uses `lib/core/di/dependency_injection.dart` (not `lib/core/dependency_injection/dependency_injection.dart`).
- Existing WIP docs in `doc/phases/unified_screen_model/*` describe an older implementation; treat them as historical.

## Mechanical search checklist (use before/after each phase)
These searches help ensure no boundary violations and to find all call sites:

- Find domain-service calls in widgets:
  - `getIt<` in `lib/presentation/**`
  - specifically: `getIt<EntityActionService>`
- Find templateId string usage:
  - `SectionTemplateId\.`
  - `templateId ==` and `switch (section.templateId)`
- Find casts that the sealed VM should eliminate:
  - `as ListSectionParamsV2`
  - `as InterleavedListSectionParamsV2`
  - `as AgendaSectionParamsV2`
  - `as HierarchyValueProjectTaskSectionParamsV2`
- Find persistence key ad-hoc formats:
  - `persistenceKey = '\$screenKey:`
  - `PageStorage\.of\(context\)\.writeState`

## Acceptance criteria (overall)
- `flutter analyze` passes with 0 errors and 0 warnings.
- No domain service calls from widgets/templates in typed USM path.
- Adding a new module/template requires:
  - domain: add mapping in module registry
  - presentation: add mapping in renderer registry
  - optionally: add a new `SectionVm` variant
- Section failures do not blank the entire screen.
- Persistence keys remain stable in behavior (format centralized, but output equivalent).

## Flexibility note
Exact filenames and method signatures in later phases should be treated as **suggested defaults**.

Hard requirements are:
- ownership boundaries
- registry-based extensibility
- sealed, typed section VMs
- error localization
- centralized identity formatting

If the repo already has an established pattern (naming, folders, DI style), prefer matching it.

## Doc update requirements
If responsibilities/flow change, update:
- [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](../../architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md)

At minimum, reflect:
- Actions cubit responsibilities and ownership of domain calls.
- Registries (domain and presentation) and where to add new mappings.
- Sealed `SectionVm` and how templates/renderers consume it.
- Error semantics (section vs screen fatal).

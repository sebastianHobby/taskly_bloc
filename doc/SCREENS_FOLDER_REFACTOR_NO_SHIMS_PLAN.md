# Unified Screens Folder Refactor — No-Shims Plan

> Audience: developers + architects
>
> Scope: refactor the **unified screen system** folders to make the boundaries between **catalog**, **templates**, and **runtime** explicit, while preserving the existing Domain/Data/Presentation split.
>
> Constraint: **no shims**. After the refactor, the old import paths will not exist; all imports must be updated in the same change set (or in a tightly coordinated sequence of commits that always keeps `main` green).

---

## 1) Goals (Why do this)

The unified screen model already works and is well documented in [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](UNIFIED_SCREEN_MODEL_ARCHITECTURE.md). The problem is navigability:

- It’s not obvious where to add:
  - a **new system screen** (Inbox/My Day/etc)
  - a **new section template** (new params + interpreter + renderer)
  - a **runtime orchestration change** (interpreter pipeline)
- Current folders mix axes:
  - “Screens” is a cross-layer feature, but parts live under general `models/` and `services/` buckets.

This refactor makes “what to touch” obvious by establishing three stable concepts:

- **Catalog**: *which screens exist* (system templates + default definitions)
- **Templates**: *which section types exist* (template IDs, params, codec, interpreters, renderers)
- **Runtime**: *how definitions become UI* (ScreenDataInterpreter pipeline + presentation shell)

---

## 2) Non-goals (What stays the same)

- No UX changes.
- No business-logic changes.
- No database schema changes.
- No behavior changes in routing, seeding, cleanup, interpreter semantics, or renderers.
- No attempt to reorganize unrelated features (tasks/projects/values/etc).

---

## 3) Target Folder Structure (end state)

This keeps the top-level layers and makes a dedicated `screens/` module inside each relevant layer.

```text
lib/
  core/
    dependency_injection/
    routing/
    theme/
    l10n/
    utils/

  domain/
    screens/
      language/
        models/
      templates/
        params/
        interpreters/
        params_codec.dart
        interpreter_registry.dart
        template_ids.dart
      runtime/
        screen_data.dart
        screen_data_interpreter.dart
        section_vm.dart
        section_data_result.dart
        (other orchestration helpers)
      catalog/
        system_screens/
        system_screen_provider.dart

  data/
    infrastructure/
      drift/
      powersync/
      supabase/

    screens/
      repositories/
      daos/
      mappers/
      maintenance/

  presentation/
    screens/
      view/
      bloc/
      templates/
        renderers/
        widgets/
      tiles/
      widgets/

    widgets/
      section_widget.dart   # may remain shared, but imports update to new locations
```

### 3.1 Practical conventions

- **A “screen X” is configuration**, not a widget:
  - It belongs under `domain/screens/catalog/system_screens/` as a `ScreenDefinition` (and helpers).
- **A “template” has a complete cross-layer footprint**:
  - Domain: params + interpreter
  - Presentation: renderer
  - Optional data/persistence support (repositories) belongs where it already lives (not necessarily inside screens).

---

## 4) Mapping: Current → Target

This section lists the minimum set of moves to reach the target while preserving semantics.

### 4.1 Domain

- `lib/domain/models/screens/` → `lib/domain/screens/language/models/`
  - Includes “screen language” models like `ScreenDefinition`, `SectionRef`, `ScreenChrome`, `SectionTemplateId`, etc.
- `lib/domain/models/screens/templates/` → `lib/domain/screens/templates/params/`
  - Template params types (Freezed/JSON) move with their generated files.
- `lib/domain/services/screens/` → `lib/domain/screens/runtime/`
  - Pipeline types like `ScreenDataInterpreter`, `ScreenData`, `SectionVm`, etc.
- `lib/domain/services/screens/templates/` → `lib/domain/screens/templates/interpreters/`
  - Section interpreters and registries/codecs.

### 4.2 Data

- `lib/data/features/screens/` → `lib/data/screens/`
  - `repositories/`, `daos/`, `default_system_screen_provider.dart`
- Maintenance that currently lives outside `data/features/screens/` (example paths referenced in the architecture doc):
  - `lib/data/services/screen_seeder.dart` → `lib/data/screens/maintenance/screen_seeder.dart`
  - `lib/data/services/system_data_cleanup_service.dart` → `lib/data/screens/maintenance/system_data_cleanup_service.dart`

(If those maintenance services are used outside screens, keep their public API unchanged—only paths/imports change.)

### 4.3 Presentation

- `lib/presentation/features/screens/` → `lib/presentation/screens/`
  - `view/`, `bloc/`, `renderers/`, `tiles/`, `widgets/`, `models/`
- Template renderers end state:
  - `lib/presentation/screens/templates/renderers/`

### 4.4 Tests

- `test/**` imports need to match the new library paths.
- Keep the same test folder split (domain/data/presentation) unless you explicitly want to refactor tests too.

---

## 5) Why “no shims” is expensive (and why it may still be worth it)

No-shims means:

- All imports across `lib/` and `test/` must be updated atomically.
- You will likely touch hundreds of import lines.
- Many screen language + template param models use `freezed` and `json_serializable`, so you must:
  - move the source files
  - re-run build_runner
  - ensure generated outputs are clean

The upside:

- End state is clean.
- No lingering duplicate exports or compatibility wrappers.
- New developers learn a single mental model.

---

## 6) Implementation Plan (No Shims)

### 6.1 Preconditions

- `flutter analyze` is green before starting.
- `dart run build_runner build --delete-conflicting-outputs` is known-good.
- You can run at least the core unit/widget test suite for screens-related tests.

### 6.2 Step-by-step sequence (recommended)

Order matters. Start with the layers with the least codegen risk.

#### Step 1 — Presentation screens move

1. Move folder:
   - `lib/presentation/features/screens/**` → `lib/presentation/screens/**`
2. Update all imports referencing `package:taskly_bloc/presentation/features/screens/...`
3. Update cross-cutting switchboard:
   - `lib/presentation/widgets/section_widget.dart` imports of renderers / screens pages
4. Run:
   - `flutter analyze`

Why first: presentation has little/no codegen and will quickly reveal missing imports.

#### Step 2 — Data screens move

1. Move:
   - `lib/data/features/screens/**` → `lib/data/screens/**`
2. Move maintenance services (if you adopt the maintenance split):
   - `lib/data/services/screen_seeder.dart` → `lib/data/screens/maintenance/screen_seeder.dart`
   - `lib/data/services/system_data_cleanup_service.dart` → `lib/data/screens/maintenance/system_data_cleanup_service.dart`
3. Update DI wiring imports (likely in `lib/core/dependency_injection/**`).
4. Run:
   - `flutter analyze`

#### Step 3 — Domain runtime + interpreters move

1. Move:
   - `lib/domain/services/screens/**` → `lib/domain/screens/runtime/**`
   - `lib/domain/services/screens/templates/**` → `lib/domain/screens/templates/interpreters/**`
2. Update imports from `package:taskly_bloc/domain/services/screens/...`
3. Run:
   - `flutter analyze`

#### Step 4 — Domain language + params move (codegen-heavy)

1. Move language models:
   - `lib/domain/models/screens/**` → `lib/domain/screens/language/models/**`
2. Move template params:
   - `lib/domain/models/screens/templates/**` → `lib/domain/screens/templates/params/**`
3. Update imports from `package:taskly_bloc/domain/models/screens/...`
4. Run codegen:
   - `dart run build_runner build --delete-conflicting-outputs`
5. Run:
   - `flutter analyze`

#### Step 5 — Update docs and navigation helpers

- Update [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](UNIFIED_SCREEN_MODEL_ARCHITECTURE.md) “Where Things Live” paths.
- If you maintain feature entrypoints like `screens.dart` barrel files, update them to export the new locations.

#### Step 6 — Fix tests

- Update imports under `test/**` to the new paths.
- Run focused tests:
  - Unit tests for domain screen language/runtime
  - Widget tests for unified screen rendering

---

## 7) Validation Checklist (Definition of Done)

- `flutter analyze` passes.
- `build_runner` completes cleanly.
- Core test suite passes (at minimum: screens-related unit + widget tests).
- No imports reference:
  - `package:taskly_bloc/domain/models/screens/...`
  - `package:taskly_bloc/domain/services/screens/...`
  - `package:taskly_bloc/presentation/features/screens/...`
  - `package:taskly_bloc/data/features/screens/...`
- Architecture docs reflect the new “catalog/templates/runtime” boundaries.

---

## 8) Risks and Mitigations

- **Risk: codegen churn and merge conflicts**
  - Mitigation: keep the change in a single dedicated PR; avoid mixing functional changes.
- **Risk: lots of touched files makes review hard**
  - Mitigation: split commits by layer (presentation → data → domain services → domain models + codegen → tests).
- **Risk: generated files location ambiguity**
  - Mitigation: rely on `build_runner` and avoid manually moving generated outputs; let the generator recreate them.

---

## 9) Decision Record (Why this structure)

- Unified screens are *not* “features per screen”; they are a **single system** with many configurations.
- This folder layout optimizes for the common contributor workflows:
  - “Add a system screen” → go to `domain/screens/catalog/system_screens/`
  - “Add a template” → go to `domain/screens/templates/*` and `presentation/screens/templates/*`
  - “Change how screens are interpreted” → go to `domain/screens/runtime/`
- Keeps domain/data/presentation boundaries intact while making the screen system’s internal boundaries explicit.

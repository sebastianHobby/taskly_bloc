# Legacy Architecture Overview (Being Migrated Away From)

> Audience: developers + architects
>
> Scope: a single, centralized overview of the legacy UI composition + routing
> mechanisms that Taskly is migrating away from.
>
> Status: legacy — do not extend.

## 1) What This Document Is

This repo historically used a **Unified Screen Model (USM)** to build large parts
of the UI from typed specs interpreted at runtime. The migration direction is to
replace USM-driven screens with **explicit, hand-authored Flutter screens** and
feature-specific **BLoCs**, while keeping the broader offline-first architecture
(Drift + PowerSync + Supabase) intact.

This document exists so the rest of `doc/architecture/` can describe only the
**future-state** architecture.

## 2) Legacy Components (USM)

The legacy USM pipeline centered on these concepts:

- **`ScreenSpec`**: typed screen definition (template + module specs + chrome)
- **System screen catalog**: in-code specs (e.g., `SystemScreenSpecs`)
- **Convention routing**: a catch-all route (historically `/:segment`) mapped a
  URL segment to a screen key/spec
- **Runtime interpretation**:
  - a spec interpreter (e.g., `ScreenSpecDataInterpreter`) routed module params
    to typed interpreters
  - each module interpreter produced reactive “section view-model” streams
- **Unified rendering**: a generic page (e.g., `UnifiedScreenPageFromSpec`) used
  a single screen BLoC to subscribe/compose and then render template/sections

High-level legacy flow:

```text
Route (/:segment)
  -> screen key
  -> load ScreenSpec (system screens + persisted prefs)
  -> interpret modules into section VMs (streams)
  -> combine into screen VM
  -> generic template renderer renders sections
```

## 3) Why It’s Being Removed

USM provided strong reuse and a typed composition mechanism, but it also:

- introduced a complex spec/runtime pipeline that is hard to evolve safely
- encouraged “everything is a module” growth and cross-feature coupling
- made incremental UX iteration slower than explicit Flutter screens
- created an extra indirection layer between routing, UI, and feature state

The migration objective is a simpler and more maintainable presentation layer:

- **Explicit routes** (no catch-all `/:segment`)
- **Explicit screens/pages** per feature
- **BLoC-owned subscriptions** and a clean presentation boundary

## 4) What To Do If You Find USM References

- Do not add new USM screens/modules/templates.
- Prefer migrating the screen/feature to the future-state patterns described in
  [SCREEN_ARCHITECTURE.md](SCREEN_ARCHITECTURE.md).
- If a doc needs historical context, link here instead of re-documenting USM.

# Phase 05 — USM-004 (Option B): Error semantics + cleanup

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Outcome
Ensure errors are localized to the failing section/module wherever possible:
- Section stream failures should yield a section-level error VM.
- Screen-level error states should be reserved for truly fatal cases:
  - gate evaluation failures
  - interpreter infrastructure failures (registry missing required mapping)

This improves resilience and reduces “blank screen because one section errored”.

## AI instructions (required)
- Review architecture docs under `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- This is the **last phase**: fix **any** `flutter analyze` error or warning (regardless of whether it is related).

## Domain changes
### Localize module stream errors
Wherever module streams are combined (currently in `ScreenSpecDataInterpreter`), ensure each module stream is protected:

- For each module’s `watch(...)` stream:
  - `onErrorReturnWith((error, st) => <SectionVmErrorVariant>(...))`

Implementation location depends on Phase 02 structure:
- Preferred: inside `ScreenModuleInterpreterRegistryImpl.watch(...)` so every module mapping is protected.

Flexibility:
- If some interpreters already return error-aware VMs, do not wrap twice.
- Preserve stack traces in logs even if UI only shows `error.toString()`.

### Distinguish “fatal” vs “section” error
- Section-level error: represented by an error VM variant (e.g. `UnknownSectionVm` or `*SectionVm(error: ...)`).
- Fatal: `ScreenSpecData.error` (or keep `ScreenSpecBloc` error state) only if:
  - gate stream fails in `_watchGateActive`
  - spec itself is malformed (should be rare; ideally represented as a dedicated gate/template)

## Presentation changes
- Ensure `SectionWidget` renders a section error VM in a clear, compact way (existing behavior already prints text).
- Ensure a single section error does not prevent other sections from rendering.

## Cleanup tasks
1) Remove any now-dead helpers that existed only to support `Object` params/data.
2) Update `ScreenTemplateWidget` filtering logic to work with sealed VMs (if not already done).
3) Update any remaining direct string usages where easy (ScreenKey/template ID wrappers).
4) Update docs:
   - [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](../../architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md) to reflect:
     - separate actions cubit
     - registries
     - sealed VMs
     - localized errors

## Verification checklist
- `flutter analyze` passes with 0 errors and 0 warnings.
- A failing section does not blank the entire screen.
- `ScreenSpecBloc` continues to load and update screen data streams.

## Manual smoke tests (suggested)
- Navigate to a system screen (e.g. My Day) and:
  - complete/uncomplete a task
  - pin/unpin a task
  - open task editor via routing
- Ensure scroll state persists where it did previously (persistence keys unchanged in behavior).

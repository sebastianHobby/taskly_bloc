# Phase 02 — USM-002 (Option B + A): Renderer registry + Module interpreter registry

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Outcome
Eliminate the two large “switchboards” that grow linearly with every new module/section:
- Domain: module → interpreter routing in `ScreenSpecDataInterpreter`.
- Presentation: section rendering `switch` in `SectionWidget`.

Replace with explicit registries:
- **Domain**: `ScreenModuleInterpreterRegistry` (approved USM-002A)
- **Presentation**: `SectionRendererRegistry` (approved USM-002B)

## AI instructions (required)
- Review architecture docs under `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.

## Domain registry (module → SectionVm stream)
### New interfaces
Create a domain-level registry interface that hides concrete interpreters.

Flexibility: the registry can be keyed by `ScreenModuleSpec` (recommended) and return a stream of section VMs. The exact VM type will evolve in Phase 04.

Suggested file: `lib/domain/screens/runtime/module_interpreter_registry.dart`

Suggested API (keep it simple):
- `Stream<SectionVm> watch({required int index, required ScreenModuleSpec module});`

If Phase 04 changes `SectionVm` into a sealed hierarchy, keep the registry returning the new base `SectionVm` type.

Implementation:
- File: `lib/domain/screens/runtime/module_interpreter_registry_impl.dart`
- Constructor injects the existing typed interpreters (same deps currently injected into `ScreenSpecDataInterpreter`).
- `watch(...)` uses `module.map(...)` internally (like the current `_watchModule`) and returns `SectionVm` stream.

### Refactor `ScreenSpecDataInterpreter`
- File: `lib/domain/screens/runtime/screen_spec_data_interpreter.dart`

Changes (intent):
- Replace the many interpreter fields with a single injected registry:
  - `required ScreenModuleInterpreterRegistry moduleRegistry`
- Replace `_watchModule(...)` implementation to delegate to the registry.
- Preserve gate evaluation logic in `ScreenSpecDataInterpreter`.

Implementation flexibility:
- It is OK if you keep `_ModuleEntry` locally, but the actual module→interpreter mapping must live in the registry.

### DI
- Update `lib/core/di/dependency_injection.dart`
  - register registry impl as lazy singleton.
  - update `ScreenSpecDataInterpreter` registration to accept registry.

## Presentation registry (templateId → renderer)
### Why
`SectionWidget` currently does:
- checks for loading/error
- then does a long `switch` over result type + `templateId`
- with repeated casting and special cases.

That makes new templates error-prone (forgetting to add in all places).

### New types
Create a renderer registry that maps template identity to a builder.

Flexibility:
- Before Phase 04: key can be `String templateId`.
- After Phase 04: key can be `SectionTemplateIdValue` or (optionally) VM runtime type.

The hard requirement: `SectionWidget` should not grow linearly as you add templates.

- File: `lib/presentation/screens/templates/section_renderer_registry.dart`

Suggested API (adjust as needed):
- `typedef SectionRenderer = Widget Function(SectionRenderContext ctx);
  @immutable
  class SectionRenderContext {
    const SectionRenderContext({
      required this.section,
      required this.persistenceKey,
      required this.displayConfig,
      required this.focusMode,
      required this.onEntityTap,
      required this.onEntityHeaderTap,
      required this.onTaskCheckboxChanged,
      required this.onTaskPinnedChanged,
      required this.onProjectCheckboxChanged,
      required this.onTaskDelete,
      required this.onProjectDelete,
    });
    final SectionVm section;
    final String? persistenceKey;
    final DisplayConfig? displayConfig;
    final FocusMode? focusMode;
    // callbacks...
  }

  abstract interface class SectionRendererRegistry {
    SectionRenderer? rendererFor(String templateId);
  }`

Implementation:
- File: `lib/presentation/screens/templates/section_renderer_registry_impl.dart`
- `rendererFor` returns closures that build the correct sliver/widget.

### Refactor `SectionWidget`
- File: `lib/presentation/widgets/section_widget.dart`

Changes:
- Keep handling for:
  - loading state
  - section.error
  - unknown section fallback
- Remove template-specific rendering logic from `SectionWidget`.
- Instead:
  - get registry via DI **OR** inject as constructor param from templates.

Preferred (keeps widgets pure and testable):
- Inject registry into `SectionWidget` via constructor param from the template widgets.

Example:
- `SectionWidget(..., rendererRegistry: context.read<SectionRendererRegistry>(), ...)`

However, there is no bloc/provider for registries currently; simplest is DI:
- `final registry = getIt<SectionRendererRegistry>();`

If you use DI in widgets, ensure it is **presentation-only** (no repositories/services).

### DI
- Register `SectionRendererRegistryImpl` as lazy singleton.

## Mechanical implementation steps
1) Add domain registry interface + impl.
2) Refactor `ScreenSpecDataInterpreter` to use registry.
3) Add presentation registry interface + impl.
4) Refactor `SectionWidget` to delegate to registry.
5) Update DI registrations.
6) Run `flutter analyze` and fix any issues.

## Verification checklist
- Adding a new module/template requires adding exactly one mapping in:
  - `ScreenModuleInterpreterRegistryImpl`
  - `SectionRendererRegistryImpl`
- `ScreenSpecDataInterpreter` no longer needs to know about every interpreter.
- `SectionWidget` is small and generic.

## Notes / forward-compat
- This phase is designed to be compatible with Phase 04 (sealed `SectionVm`).
  Keep the registry signatures general enough to adjust from `String templateId` to value types later.

# Phase 02 — Wire EntityStyleV1 into USM Runtime (SectionVm + interpreters)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Goal
Make `EntityStyleV1` a first-class, runtime-provided input to presentation renderers by threading it through USM runtime outputs. This ensures renderers do not have to infer styling from enrichment or section types.

## Non-goals
- No UI/UX redesign.
- Do not refactor presentation renderers yet beyond what is strictly required to compile.

## Work Items
### 1) Add style to SectionVm variants that render entities
- Update `SectionVm` variants for entity-rendering sections to carry an `EntityStyleV1 entityStyle`:
  - `agendaV2`
  - `taskListV2`
  - `interleavedListV2`
  - `hierarchyValueProjectTaskV2`
  - any other section that produces task/project/value tiles

Files likely involved:
- `lib/domain/screens/runtime/section_vm.dart`
- `lib/domain/screens/language/models/section_template_id.dart` (for mapping usage)

### 2) Compute entityStyle during module interpretation
- In `ScreenModuleInterpreterRegistry` (or the closest point where SectionVm is constructed), compute:
  - `entityStyle = resolver.resolve(template: screenSpec.template, sectionTemplateId: sectionVm.templateId, override: moduleOverride)`
- Introduce module-level optional override for relevant module params.
  - Choose a single place to store override:
    - Preferred: add `EntityStyleOverrideV1? styleOverride` to relevant params types (e.g., `ListSectionParamsV2`, `InterleavedListSectionParamsV2`, `AgendaSectionParamsV2`, `Hierarchy...ParamsV2`).

### 3) Remove StylePackV2 usage from params
- Replace `pack: StylePackV2` in list-like params with either:
  - `entityStyleOverride` + runtime default, OR
  - `EntityDensityV1 density` if params must still specify density.

Explicit goal: delete `StylePackV2` completely by end of Phase 03, but Phase 02 should remove it from the domain params surface and migrate call sites.

### 4) Update system screen specs to use new model
- Update `SystemScreenSpecs` to remove `pack: StylePackV2.standard` from params.
- Any density choices become resolver defaults or explicit overrides.

Files likely involved:
- `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`
- Param files under `lib/domain/screens/templates/params/`

## Acceptance Criteria
- `SectionVm` carries `EntityStyleV1` where entity tiles are rendered.
- `SystemScreenSpecs` compiles without `StylePackV2`.
- Domain layer compiles with style resolved by (template,module) and optional overrides.

## AI Instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- When the phase is complete, update this file immediately with:
  - `Last updated at:` (UTC)
  - a short summary of what was done
  - the phase completion timestamp (UTC)

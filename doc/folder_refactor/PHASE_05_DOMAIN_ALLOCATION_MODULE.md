# Phase 05 — Domain: Modularize Allocation (and align Attention integration points)

## Goal

Make Allocation consistent with the system-module approach used for Attention and now Screens.

This phase is about **moving** allocation domain code into a coherent module shape, without changing behavior.

## Moves (mechanical)

### Allocation module

Move allocation-related domain code into:

- `lib/domain/allocation/model/**`
- `lib/domain/allocation/engine/**`
- `lib/domain/allocation/contracts/**`

Candidate sources (based on architecture docs):

- Models:
  - `lib/domain/models/settings/allocation_config.dart`
  - `lib/domain/models/settings/focus_mode.dart`
  - `lib/domain/models/priority/allocation_result.dart`
  - `lib/domain/models/allocation/allocation_snapshot.dart`

- Engine/services:
  - `lib/domain/services/allocation/**`

- Contracts:
  - `lib/domain/interfaces/allocation_snapshot_repository_contract.dart`

### Time services

Leave time services where they are unless you explicitly want them in allocation:

- Keep:
  - `lib/domain/services/time/**`

(Allocation depends on time triggers but does not necessarily own the time subsystem.)

## Import updates

Update imports across `lib/**`.

Examples:

- `package:taskly_bloc/domain/services/allocation/...`
  → `package:taskly_bloc/domain/allocation/engine/...`

- `package:taskly_bloc/domain/models/settings/allocation_config.dart`
  → `package:taskly_bloc/domain/allocation/model/allocation_config.dart`

- `package:taskly_bloc/domain/interfaces/allocation_snapshot_repository_contract.dart`
  → `package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart`

## Screens integration touchpoints

Allocation’s screen integration points moved in Phase 04 (templates/runtime/language). Update allocation code to import:

- Screen template IDs and params from `domain/screens/templates/*` and `domain/screens/language/*`.
- Any screen gating types from `domain/screens/runtime/*` or `language/*` depending on where they live.

## Analyze and fix (required at end of phase)

- Run `flutter analyze`.
- Fix all errors/warnings.

## Do NOT do in this phase

- Do not run tests.
- Do not change allocation behavior, defaults, or tuning.

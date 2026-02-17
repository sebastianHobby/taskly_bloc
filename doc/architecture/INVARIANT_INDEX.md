# Invariant Index

Quick index for `doc/architecture/INVARIANTS.md`.

## Layering and boundaries

- `INV-LAYER-001`: Dependency direction and layering boundaries (section 1.1).
- `INV-LAYER-002`: No package `src/` deep imports (section 1.3).
- `INV-LAYER-003`: Domain purity and view-neutral outputs (sections 0.1.1, 1.4).
- `INV-DI-001`: Service locator usage limited to composition roots (section 1.5).

## Presentation and state

- `INV-PRES-001`: BLoC-only state boundary for widgets/pages (section 2).
- `INV-PRES-002`: Query services are presentation-layer only and read-only (section 2.0.1).
- `INV-PRES-003`: Session shared stream cache ownership rules (section 2.0.2).
- `INV-ROUTE-001`: Routing and side-effect boundaries (section 2.6).
- `INV-STREAM-001`: Reactive subscription lifecycle safety (section 3.1).

## Testing

- `INV-TEST-001`: Hermetic test policy (section 3.3 TG-001-A).
- `INV-TEST-002`: Safe wrappers and no leaked resources (section 3.3 TG-002-A/TG-003-A).
- `INV-TEST-003`: No wall-clock and deterministic stream seeding policies (section 3.3).
- `INV-TEST-004`: Directory/tag taxonomy contract (section 3.4).

## Writes and recurrence

- `INV-WRITE-001`: Single write boundary per feature (section 4.1).
- `INV-WRITE-002`: Recurrence command/read boundaries (sections 4.3, 4.4).
- `INV-WRITE-003`: Transactionality for multi-table writes (section 4.2).

## Sync, time, and errors

- `INV-SYNC-001`: Local-first with PowerSync constraints (section 5).
- `INV-SYNC-002`: No UPSERT against PowerSync-backed view tables (section 5.2).
- `INV-TIME-001`: No direct `DateTime.now()` in domain/data/presentation (section 7).
- `INV-ERR-001`: Typed failure mapping across boundaries (section 8.0).
- `INV-ERR-002`: `OperationContext` required for user-initiated writes (section 8.1).

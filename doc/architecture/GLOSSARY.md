# Architecture Glossary

Short definitions for recurring terms used in Taskly architecture docs.

- Business semantics: product rules that must be consistent across screens
  (recurrence targeting, validation, canonical sorting, write orchestration).
- Presentation policy: screen-specific behavior (loading UX, pagination,
  sectioning, optimistic UI, mapping domain entities to UI models).
- Screen-shaped reactive composition: combining domain streams into a single
  screen state machine in a BLoC.
- BLoC boundary: widgets trigger events and render state; they do not call
  repositories or subscribe to domain/data streams directly.
- Offline-first: local SQLite is the source of truth; sync converges with the
  backend.
- OperationContext: correlation metadata created at the presentation boundary
  for every user-initiated write.
- Occurrence: a virtual instance of a recurring entity (task/project) derived
  from recurrence rules.
- Home day key: the app-defined day identifier used for recurrence targeting
  and scheduling semantics.
- Query service: presentation-layer helper that derives a single stream for a
  screen (no writes, no routing, no widgets).

# Phase 02 — Attention Cached Engine + Boot Prewarm (+ Inbox gating)

Created at: 2026-01-14T10:45:52.1300375Z (UTC)
Last updated at: 2026-01-14T10:45:52.1300375Z (UTC)

## Outcome

- A single evaluation pipeline per `AttentionQuery` shared across the app.
- Late subscribers (Inbox, banners, screens) receive the latest computed value immediately.
- Boot prewarm starts the expensive queries early without blocking first frame.

## Design

### 1) Cached engine decorator

- Add `CachedAttentionEngine` implementing `AttentionEngineContract`.
- Wrap the existing concrete engine.
- Cache **shared replaying streams** keyed by query semantics.

Cache behavior:
- Sharing: multiple subscribers must reuse the same upstream evaluation.
- Replay: new subscribers immediately get the last emitted value.
- Errors: do not permanently cache errors; prefer allowing retries.
- Invalidation: include a manual `invalidateAll()` or `invalidate(query)` hook for debug/maintenance.

### 2) Cache key

- Prefer a stable cache key type derived from the query (bucket + any filters/params used by evaluation).
- If `AttentionQuery` already has correct equality/hashCode and is immutable, it can be used directly.

### 3) Boot prewarm

- Add `AttentionPrewarmService` started from `bootstrap.dart` after DI is initialized.
- Start prewarm asynchronously (microtask / `unawaited`) so it does not delay app startup.
- Prewarm queries:
  - Inbox: Action bucket query + Review bucket query.
  - Any banner queries used by unified screens (match the interpreter inputs).

### 4) Inbox gating fix (so UI doesn’t block on the slow stream)

Even with caching, the first-ever Action evaluation may still be slow. The Inbox page should not show a global spinner waiting for both tabs.

Implement one of:
- Seed each tab stream with an empty initial value (`startWith(const <AttentionItem>[])`).
- Or decouple: load Review immediately and let Action load independently.

## Files likely involved

- Domain:
  - `lib/domain/attention/contracts/attention_engine_contract.dart`
  - `lib/domain/attention/engine/cached_attention_engine.dart` (new)
  - `lib/domain/services/attention/attention_prewarm_service.dart` (new)
- DI + bootstrap:
  - `lib/core/di/dependency_injection.dart`
  - `lib/bootstrap.dart`
- Presentation:
  - `lib/presentation/features/attention/bloc/attention_inbox_bloc.dart`

## Acceptance criteria

- Attention no longer blocks initial UI on Action’s first emission.
- Reopening Inbox (warm) is instant for both tabs.
- Screens using the attention banner do not duplicate evaluation work across multiple subscribers.

## AI instructions

- Review `doc/architecture/` before implementing changes.
- Run `flutter analyze` for this phase.
- Ensure any analyzer errors/warnings caused by this phase are fixed by the end of the phase.

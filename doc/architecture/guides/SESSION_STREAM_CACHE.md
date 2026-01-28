# Session Stream Cache -- Guide

> Audience: developers
>
> Scope: the session-scoped stream cache pattern and where it is used.
> Descriptive only; invariants live in [../INVARIANTS.md](../INVARIANTS.md).

## 1) Why this exists

Some streams are shared across multiple screens (values list, allocation
snapshots, inbox counts). The **session stream cache** prevents duplicate
subscriptions and keeps lifecycle behavior consistent.

## 2) Core behavior

- Caches streams by key as replaying `ValueStream`s.
- Pauses subscriptions on background when configured.
- Resubscribes sources on resume.

See implementation:
- `lib/presentation/shared/services/streams/session_stream_cache.dart`

## 3) Related session services

Session-level services that build on the cache:

- `lib/presentation/shared/session/session_shared_data_service.dart`
- `lib/presentation/shared/session/session_allocation_cache_service.dart`
- `lib/presentation/shared/session/presentation_session_services_coordinator.dart`

DI registration and startup:
- `lib/core/di/dependency_injection.dart`
- `lib/presentation/features/app/view/app.dart`

## 4) Usage patterns

Typical flow:

```text
Screen BLoC -> screen query service -> session shared service -> cache manager
```

Examples:
- `lib/presentation/screens/services/my_day_query_service.dart`
- `lib/presentation/features/anytime/services/anytime_session_query_service.dart`
- `lib/presentation/features/scheduled/services/scheduled_session_query_service.dart`

## 5) Notes

- Prefer cache-managed streams for cross-screen shared data.
- Keep stream lifecycle owned by presentation services, not widgets.


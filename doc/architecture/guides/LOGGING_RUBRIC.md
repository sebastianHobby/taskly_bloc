# LOGGING_RUBRIC

Status: Active

This guide defines the repo-wide logging-level rubric and signal quality
expectations. It is complementary to `INVARIANTS.md` (error mapping +
`OperationContext` correlation).

## Level rubric

- `routine` / `debug`:
  - High-volume expected events.
  - Lifecycle chatter useful during local investigation.
  - Should be throttled if emitted from streams or build paths.
- `info`:
  - Milestones and state transitions (start/stop/success checkpoints).
  - Should remain relatively low-volume.
- `warning`:
  - Degraded-but-recoverable behavior.
  - Must be actionable and indicate potential reliability risk.
- `error`:
  - Operation failed but no exception object/stack is available.
- `handle`:
  - Operation failed with exception + stack trace.
  - Preferred for caught exceptions.

## Structured context requirements

For `info`/`warning`/`error`/`handle`, include structured context whenever
available:

- `feature`
- `screen`
- `intent`
- `operation`
- `correlationId`
- entity identifiers (`entityType`, `entityId`) when relevant

Preferred pattern:

```dart
AppLog.handleStructured(
  'category',
  'operation failed',
  error,
  stackTrace,
  context.toLogFields(),
);
```

## Sensitive/high-cardinality data policy

- Do not log raw user identifiers.
  - Use `user_id_hash` for correlation.
- Route logging defaults to route name only.
  - Route arguments are gated behind diagnostics flags.
- Avoid dumping large payloads in warning/error logs.
  - Prefer bounded previews and samples.

## Fire-and-forget async policy

`unawaited(...)` paths must capture local errors:

```dart
unawaited(
  someAsyncCall().catchError((Object error, StackTrace stackTrace) {
    AppLog.handleStructured(
      'category',
      'background operation failed',
      error,
      stackTrace,
      fields,
    );
  }),
);
```


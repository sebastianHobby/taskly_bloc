# New Feature Checklist

Use this when adding a new screen, flow, or domain capability.

## 1) Architecture basics

- Read [INVARIANTS.md](../INVARIANTS.md) and the relevant guide for your area.
- Confirm the layer ownership: presentation (screen/BLoC), domain (semantics),
  data (persistence).
- If a change alters boundaries or responsibilities, update architecture docs.

## 2) Presentation boundary (BLoC-only)

- Widgets raise events and render state; they do not call repositories/services
  or subscribe to domain/data streams directly.
- BLoC owns subscriptions and produces widget-ready state.
- Use query services for repeatable screen composition when it keeps BLoC thin.

## 3) Write path

- Create/extend a domain use-case or write facade for any user-initiated write.
- Create an OperationContext at the BLoC boundary and pass it through to data.
- Normalize optional IDs (empty/whitespace to null) at the write boundary.
- Ensure multi-table writes are atomic (transaction).

## 4) Time and recurrence

- Do not call DateTime.now() in presentation, domain, or data.
- Use the injected time service.
- For recurring entities, resolve occurrence targeting in domain, not UI.

## 5) Streams and lifecycle

- Bind streams with emit.forEach/emit.onEach; avoid emit after handler completes.
- Make stream contracts explicit (broadcast, replay, cold/hot).
- Do not cache single-subscription streams across listeners.

## 6) Error handling

- Prefer typed failures/results over raw exceptions across boundaries.
- Reactive streams should map failures into UI state, not terminate UI.

## 7) Tests (when added)

- Use testSafe/testWidgetsSafe/blocTestSafe helpers.
- Keep unit/widget tests hermetic by default.
- Ensure resources are cleaned up with addTearDown.

## 8) UI reuse and taskly_ui

- New primitives/entities/sections live in taskly_ui.
- Shared UI is data-in/events-out only; no routing or DI in taskly_ui.

## 9) Guardrails and exceptions

- Run guardrail scripts when you touch boundaries or data rules.
- If an invariant must be violated, document an exception before coding.

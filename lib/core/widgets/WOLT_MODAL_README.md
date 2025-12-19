Wolt modal usage (helpers)
===========================

Purpose
-------
This file documents the `showDetailModal` helper in `wolt_modal_helpers.dart`.

When to use
-----------
- Use `showDetailModal(...)` instead of calling `WoltModalSheet.show` directly to keep
  modal configuration consistent across the app.

Non-scrolling pages and forms
-----------------------------
- Forms that include `EditableText` (e.g. `TextFormField`, `FormBuilderTextField`) should
  be shown using `useNonScrolling: true` (the default). In testing and on some platforms,
  `WoltModalSheetPage` can animate in a way that lets `EditableText` try to obtain
  focus before the render box has stable layout constraints, causing layout/focus
  races (tests may see "RenderBox was not laid out" errors).
- Use `useNonScrolling: false` only for multi-page or scrollable modal content where
  you handle focus/waiting in tests (e.g. `tester.pumpAndSettle()` before interacting
  with text fields).

Testing guidance
-----------------
- For callers that must use a scrollable `WoltModalSheetPage`, ensure tests wait for
  the sheet animation to finish before interacting with inputs: `await tester.pumpAndSettle();`.
- The helper also accepts `sheetOpenNotifier` (a `ValueNotifier<bool>`) which callers
  use to hide FABs while the modal is open.

Example
-------
```dart
await showDetailModal<void>(
  context: context,
  childBuilder: (modalContext) => SafeArea(
    top: false,
    child: MyDetailForm(onSuccess: (_) => Navigator.of(modalContext).pop()),
  ),
  useNonScrolling: true, // recommended for single-page forms
);
```

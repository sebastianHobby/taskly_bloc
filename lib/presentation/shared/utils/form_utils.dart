import 'package:flutter/material.dart';

/// Shows a dialog asking the user to confirm discarding unsaved changes.
///
/// Returns `true` if the user chose to discard, `false` if they chose to
/// keep editing, or `null` if they dismissed the dialog.
///
/// Example usage:
/// ```dart
/// if (_isDirty) {
///   final shouldDiscard = await showDiscardDialog(context);
///   if (shouldDiscard ?? false) {
///     Navigator.of(context).pop();
///   }
/// }
/// ```
Future<bool?> showDiscardDialog(
  BuildContext context, {
  String title = 'Discard changes?',
  String content =
      'You have unsaved changes. Are you sure you want to discard them?',
  String keepEditingText = 'Keep Editing',
  String discardText = 'Discard',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(keepEditingText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(discardText),
        ),
      ],
    ),
  );
}

/// A mixin that provides form dirty state tracking and close handling.
///
/// Use this mixin in StatefulWidget states to get consistent unsaved
/// changes behavior across all forms.
///
/// Example usage:
/// ```dart
/// class _MyFormState extends State<MyForm> with FormDirtyStateMixin {
///   @override
///   VoidCallback? get onClose => widget.onClose;
///
///   @override
///   Widget build(BuildContext context) {
///     return FormBuilder(
///       onChanged: markDirty,
///       child: // ...
///     );
///   }
/// }
/// ```
mixin FormDirtyStateMixin<T extends StatefulWidget> on State<T> {
  bool _isDirty = false;

  /// Whether the form has unsaved changes.
  bool get isDirty => _isDirty;

  /// Override to provide the close callback.
  VoidCallback? get onClose;

  /// Marks the form as having unsaved changes.
  void markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  /// Resets the dirty state (e.g., after saving).
  void clearDirty() {
    if (_isDirty) {
      setState(() => _isDirty = false);
    }
  }

  /// Handles close with unsaved changes confirmation.
  ///
  /// Shows a discard dialog if the form is dirty, otherwise closes directly.
  Future<void> handleClose() async {
    if (_isDirty) {
      final shouldDiscard = await showDiscardDialog(context);
      if ((shouldDiscard ?? false) && onClose != null) {
        onClose!();
      }
    } else {
      onClose?.call();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';

/// Helper to centralize modal usage for detail sheets.
///
/// **Adaptive behavior:**
/// - Mobile (< 600dp): Bottom sheet sliding up from bottom
/// - Tablet/Desktop (≥ 600dp): Centered dialog with rounded corners
///
/// **UX best practices:**
/// - `isScrollControlled: true` allows full-height content on mobile
/// - Rounded corners for modern Material 3 look
/// - Keyboard-aware padding via `viewInsets`
/// - Drag handle option for discoverability (mobile only)
/// - Safe area handling for notches/home indicators
///
/// Use `childBuilder` to obtain the modal's inner BuildContext so
/// callbacks that need to `Navigator.of(modalContext).pop()` can access it.
Future<T?> showDetailModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext modalContext) childBuilder,
  ValueNotifier<bool>? sheetOpenNotifier,
  bool barrierDismissible = true,
  bool useSafeArea = true,
  bool showDragHandle = false,

  /// Maximum width for dialog on large screens. Defaults to 560dp.
  double maxDialogWidth = 560,

  /// Maximum height for dialog on large screens. Defaults to 90% of screen.
  double maxDialogHeightFactor = 0.9,
}) async {
  sheetOpenNotifier?.value = true;

  final windowSizeClass = WindowSizeClass.of(context);

  final T? result;
  if (windowSizeClass.isCompact) {
    // Mobile: Bottom sheet
    result = await _showAsBottomSheet<T>(
      context: context,
      childBuilder: childBuilder,
      barrierDismissible: barrierDismissible,
      useSafeArea: useSafeArea,
      showDragHandle: showDragHandle,
    );
  } else {
    // Tablet/Desktop: Centered dialog
    result = await _showAsDialog<T>(
      context: context,
      childBuilder: childBuilder,
      barrierDismissible: barrierDismissible,
      maxWidth: maxDialogWidth,
      maxHeightFactor: maxDialogHeightFactor,
    );
  }

  sheetOpenNotifier?.value = false;
  return result;
}

/// Shows content as a bottom sheet (mobile).
Future<T?> _showAsBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) childBuilder,
  required bool barrierDismissible,
  required bool useSafeArea,
  required bool showDragHandle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: showDragHandle,
    isDismissible: barrierDismissible,
    useSafeArea: useSafeArea,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (modalContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ModalChromeScope(
                  modalHasDragHandle: showDragHandle,
                  child: childBuilder(modalContext),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows content as a centered dialog (tablet/desktop).
Future<T?> _showAsDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) childBuilder,
  required bool barrierDismissible,
  required double maxWidth,
  required double maxHeightFactor,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      final screenHeight = MediaQuery.sizeOf(dialogContext).height;
      final maxHeight = screenHeight * maxHeightFactor;

      return Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
            ),
            child: ModalChromeScope(
              modalHasDragHandle: false,
              child: childBuilder(dialogContext),
            ),
          ),
        ),
      );
    },
  );
}

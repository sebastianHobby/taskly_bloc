import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Helper to centralize WoltModalSheet usage for detail sheets.
///
/// Use `childBuilder` to obtain the modal sheet's inner BuildContext so
/// callbacks that need to `Navigator.of(modalContext).pop()` can access it.
Future<T?> showDetailModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext modalContext) childBuilder,
  ValueNotifier<bool>? sheetOpenNotifier,
  bool useNonScrolling = true,
  WoltModalType Function(BuildContext)? modalTypeBuilder,
  bool barrierDismissible = true,
  bool useSafeArea = true,
  bool showDragHandle = false,
}) async {
  sheetOpenNotifier?.value = true;

  final result = await WoltModalSheet.show<T>(
    context: context,
    useSafeArea: useSafeArea,
    barrierDismissible: barrierDismissible,
    modalTypeBuilder: modalTypeBuilder,
    showDragHandle: showDragHandle,
    pageListBuilder: (modalSheetContext) => [
      if (useNonScrolling)
        NonScrollingWoltModalSheetPage(
          child: Builder(
            builder: (modalContext) => childBuilder(modalContext),
          ),
        )
      else
        WoltModalSheetPage(
          child: Builder(
            builder: (modalContext) => childBuilder(modalContext),
          ),
        ),
    ],
  );

  sheetOpenNotifier?.value = false;
  return result;
}

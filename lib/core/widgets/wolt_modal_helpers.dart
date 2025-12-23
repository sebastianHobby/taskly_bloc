import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Helper to centralize WoltModalSheet usage for detail sheets.
///
/// Use `childBuilder` to obtain the modal sheet's inner BuildContext so
/// callbacks that need to `Navigator.of(modalContext).pop()` can access it.
///
/// Note: We use [WoltModalSheetPage] instead of [NonScrollingWoltModalSheetPage]
/// because the latter uses [SliverFillViewport] which forces content to fill
/// the entire viewport height, causing unwanted whitespace for forms.
Future<T?> showDetailModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext modalContext) childBuilder,
  ValueNotifier<bool>? sheetOpenNotifier,
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
      WoltModalSheetPage(
        hasTopBarLayer: false,
        child: Builder(
          builder: (modalContext) => childBuilder(modalContext),
        ),
      ),
    ],
  );

  sheetOpenNotifier?.value = false;
  return result;
}

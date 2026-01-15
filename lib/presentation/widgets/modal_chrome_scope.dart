import 'package:flutter/widgets.dart';

/// Inherited config for coordinating modal chrome between containers (sheet/
/// dialog) and inner content widgets.
///
/// This is used to avoid duplicated affordances like drag handles when the
/// modal container already renders one.
class ModalChromeScope extends InheritedWidget {
  const ModalChromeScope({
    required super.child,
    required this.modalHasDragHandle,
    super.key,
  });

  /// True when the modal container already renders a drag handle.
  final bool modalHasDragHandle;

  static ModalChromeScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ModalChromeScope>();
  }

  @override
  bool updateShouldNotify(ModalChromeScope oldWidget) {
    return modalHasDragHandle != oldWidget.modalHasDragHandle;
  }
}

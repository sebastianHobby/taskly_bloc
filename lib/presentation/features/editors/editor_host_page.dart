import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:taskly_bloc/presentation/features/editors/editor_feedback.dart';

/// Central host for route-backed editors.
///
/// Behavior:
/// - If the editor route has an in-app origin (back-stack), open as a modal
///   (sheet/panel/dialog) and pop the route when the modal closes.
/// - If the editor route is entered directly (deep link, no back-stack), render
///   the editor content full-page.
class EditorHostPage extends StatefulWidget {
  const EditorHostPage({
    required this.openModal,
    required this.fullPageBuilder,
    super.key,
  });

  final Future<void> Function(BuildContext context) openModal;
  final WidgetBuilder fullPageBuilder;

  @override
  State<EditorHostPage> createState() => _EditorHostPageState();
}

class _EditorHostPageState extends State<EditorHostPage> {
  bool _openedModal = false;
  bool? _useModal;
  String? _modalRouteLocation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Cache decision once. This avoids flipping presentation mid-session.
    _useModal ??= GoRouter.of(context).canPop();

    if ((_useModal ?? false) && !_openedModal) {
      _openedModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openAsModal();
      });
    }
  }

  Future<void> _openAsModal() async {
    // Guard: widget can unmount before post-frame.
    if (!mounted) return;

    _modalRouteLocation ??=
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();

    await widget.openModal(context);

    if (!mounted) return;

    final currentLocation =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    if (_modalRouteLocation != null && currentLocation != _modalRouteLocation) {
      return;
    }

    // Close the editor route (or go home if this was somehow root).
    await closeEditor(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_useModal == false) {
      return widget.fullPageBuilder(context);
    }

    // While the modal is opening, keep the route lightweight.
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

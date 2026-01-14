import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

/// Route-backed entry point for the value editor.
///
/// Routes:
/// - Create: `/value/new`
/// - Edit: `/value/:id/edit`
///
/// This page opens the value editor modal and then returns to the previous
/// route when the modal is dismissed.
class ValueEditorRoutePage extends StatefulWidget {
  const ValueEditorRoutePage({
    required this.valueId,
    super.key,
  });

  final String? valueId;

  @override
  State<ValueEditorRoutePage> createState() => _ValueEditorRoutePageState();
}

class _ValueEditorRoutePageState extends State<ValueEditorRoutePage> {
  var _opened = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openEditor();
    });
  }

  Future<void> _openEditor() async {
    if (_opened) return;
    _opened = true;

    final launcher = EditorLauncher.fromGetIt();
    await launcher.openValueEditor(
      context,
      valueId: widget.valueId,
      showDragHandle: true,
    );

    if (!mounted) return;

    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routing.screenPath('my_day'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

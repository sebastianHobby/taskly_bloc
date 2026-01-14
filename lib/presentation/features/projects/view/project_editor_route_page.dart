import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

/// Route-backed entry point for the project editor.
///
/// Routes:
/// - Create: `/project/new`
/// - Edit: `/project/:id/edit`
///
/// This page opens the project editor modal and then returns to the previous
/// route when the modal is dismissed.
class ProjectEditorRoutePage extends StatefulWidget {
  const ProjectEditorRoutePage({
    required this.projectId,
    super.key,
  });

  final String? projectId;

  @override
  State<ProjectEditorRoutePage> createState() => _ProjectEditorRoutePageState();
}

class _ProjectEditorRoutePageState extends State<ProjectEditorRoutePage> {
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
    await launcher.openProjectEditor(
      context,
      projectId: widget.projectId,
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

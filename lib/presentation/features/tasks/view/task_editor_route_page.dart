import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

/// Route-backed entry point for the task editor.
///
/// Per the core ED/RD contract, tasks are editor-only.
///
/// Canonical routes:
/// - Create: `/task/new`
/// - Edit: `/task/:id/edit`
///
/// When opened, this page launches the task editor modal and then returns to
/// the previous route when the modal is dismissed.
class TaskEditorRoutePage extends StatefulWidget {
  const TaskEditorRoutePage({
    required this.taskId,
    this.defaultProjectId,
    this.defaultValueIds,
    super.key,
  });

  final String? taskId;
  final String? defaultProjectId;
  final List<String>? defaultValueIds;

  @override
  State<TaskEditorRoutePage> createState() => _TaskEditorRoutePageState();
}

class _TaskEditorRoutePageState extends State<TaskEditorRoutePage> {
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
    await launcher.openTaskEditor(
      context,
      taskId: widget.taskId,
      defaultProjectId: widget.defaultProjectId,
      defaultValueIds: widget.defaultValueIds,
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
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

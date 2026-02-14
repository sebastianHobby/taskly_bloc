import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_host_page.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/routines/view/routine_detail_view.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';

/// Route-backed entry point for the routine editor.
///
/// Routes:
/// - Create: `/routine/new`
/// - Edit: `/routine/:id/edit`
class RoutineEditorRoutePage extends StatelessWidget {
  const RoutineEditorRoutePage({
    required this.routineId,
    this.defaultProjectId,
    this.openToProjectPicker = false,
    super.key,
  });

  final String? routineId;
  final String? defaultProjectId;
  final bool openToProjectPicker;

  @override
  Widget build(BuildContext context) {
    return EditorHostPage(
      openModal: (context) => context.read<EditorLauncher>().openRoutineEditor(
        context,
        routineId: routineId,
        defaultProjectId: defaultProjectId,
        openToProjectPicker: openToProjectPicker,
        showDragHandle: true,
      ),
      fullPageBuilder: (_) => _RoutineEditorFullPage(
        routineId: routineId,
        defaultProjectId: defaultProjectId,
        openToProjectPicker: openToProjectPicker,
      ),
    );
  }
}

class _RoutineEditorFullPage extends StatelessWidget {
  const _RoutineEditorFullPage({
    required this.routineId,
    this.defaultProjectId,
    this.openToProjectPicker = false,
  });

  final String? routineId;
  final String? defaultProjectId;
  final bool openToProjectPicker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RoutineDetailSheetPage(
          routineId: routineId,
          routineRepository: context.read<RoutineRepositoryContract>(),
          routineChecklistRepository: context
              .read<RoutineChecklistRepositoryContract>(),
          projectRepository: context.read<ProjectRepositoryContract>(),
          routineWriteService: context.read<RoutineWriteService>(),
          defaultProjectId: defaultProjectId,
          openToProjectPicker: openToProjectPicker,
        ),
      ),
    );
  }
}

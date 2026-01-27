import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
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
    super.key,
  });

  final String? routineId;

  @override
  Widget build(BuildContext context) {
    return EditorHostPage(
      openModal: (context) => EditorLauncher.fromGetIt().openRoutineEditor(
        context,
        routineId: routineId,
        showDragHandle: true,
      ),
      fullPageBuilder: (_) => _RoutineEditorFullPage(routineId: routineId),
    );
  }
}

class _RoutineEditorFullPage extends StatelessWidget {
  const _RoutineEditorFullPage({required this.routineId});

  final String? routineId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RoutineDetailSheetPage(
          routineId: routineId,
          routineRepository: getIt<RoutineRepositoryContract>(),
          valueRepository: getIt<ValueRepositoryContract>(),
          routineWriteService: getIt<RoutineWriteService>(),
        ),
      ),
    );
  }
}

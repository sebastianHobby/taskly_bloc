import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_host_page.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_detail_view.dart';

/// Route-backed entry point for the value editor.
///
/// Routes:
/// - Create: `/value/new`
/// - Edit: `/value/:id/edit`
///
/// This page opens the value editor modal and then returns to the previous
/// route when the modal is dismissed.
class ValueEditorRoutePage extends StatelessWidget {
  const ValueEditorRoutePage({
    required this.valueId,
    super.key,
  });

  final String? valueId;

  @override
  Widget build(BuildContext context) {
    return EditorHostPage(
      openModal: (context) => context.read<EditorLauncher>().openValueEditor(
        context,
        valueId: valueId,
        showDragHandle: true,
      ),
      fullPageBuilder: (_) => _ValueEditorFullPage(valueId: valueId),
    );
  }
}

class _ValueEditorFullPage extends StatelessWidget {
  const _ValueEditorFullPage({required this.valueId});

  final String? valueId;

  @override
  Widget build(BuildContext context) {
    final valueRepository = context.read<ValueRepositoryContract>();
    final valueWriteService = context.read<ValueWriteService>();

    return Scaffold(
      body: SafeArea(
        child: ValueDetailSheetPage(
          valueId: valueId,
          valueRepository: valueRepository,
          valueWriteService: valueWriteService,
        ),
      ),
    );
  }
}

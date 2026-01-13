// drift types are provided by the generated database import below
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_feedback.dart';
import 'package:taskly_bloc/presentation/shared/mixins/form_submission_mixin.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_form.dart';

class ProjectEditSheetPage extends StatelessWidget {
  const ProjectEditSheetPage({
    required this.projectRepository,
    required this.valueRepository,
    this.projectId,
    this.onSaved,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final String? projectId;

  /// Optional callback when a project is saved (created or updated).
  /// Called with the project ID after successful save.
  final void Function(String projectId)? onSaved;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectDetailBloc(
        projectRepository: projectRepository,
        valueRepository: valueRepository,
      ),
      lazy: false,
      child: ProjectEditSheetView(
        projectId: projectId,
        onSaved: onSaved,
      ),
    );
  }
}

class ProjectEditSheetView extends StatefulWidget {
  const ProjectEditSheetView({
    this.projectId,
    this.onSaved,
    super.key,
  });

  final String? projectId;

  /// Optional callback when a project is saved (created or updated).
  final void Function(String projectId)? onSaved;

  @override
  State<ProjectEditSheetView> createState() => _ProjectEditSheetViewState();
}

class _ProjectEditSheetViewState extends State<ProjectEditSheetView>
    with FormSubmissionMixin {
  // Create a global key that uniquely identifies the Form widget
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ProjectDetailBloc>();
    final projectId = widget.projectId;

    if (projectId != null && projectId.isNotEmpty) {
      bloc.add(ProjectDetailEvent.loadById(projectId: projectId));
    } else {
      bloc.add(const ProjectDetailEvent.loadInitialData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectDetailBloc, ProjectDetailState>(
      listenWhen: (previous, current) {
        return current is ProjectDetailOperationSuccess ||
            current is ProjectDetailOperationFailure ||
            current is ProjectDetailLoadSuccess;
      },
      listener: (context, state) {
        switch (state) {
          case ProjectDetailLoadSuccess(
            :final project,
          ):
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final formState = _formKey.currentState;
              if (formState == null) return;

              formState.patchValue({
                'name': project.name.trim(),
                'description': project.description ?? '',
                'completed': project.completed,
                'startDate': project.startDate,
                'deadlineDate': project.deadlineDate,
                'repeatIcalRrule': project.repeatIcalRrule ?? '',
              });
            });
          case ProjectDetailOperationSuccess(:final operation):
            unawaited(
              handleEditorOperationSuccess(
                context,
                operation: operation,
                createdMessage: context.l10n.projectCreatedSuccessfully,
                updatedMessage: context.l10n.projectUpdatedSuccessfully,
                deletedMessage: context.l10n.projectDeletedSuccessfully,
                onSaved: widget.projectId != null
                    ? () => widget.onSaved?.call(widget.projectId!)
                    : null,
              ),
            );
          case ProjectDetailOperationFailure(:final errorDetails):
            showEditorErrorSnackBar(context, errorDetails.error);
          default:
            return;
        }
      },
      buildWhen: (previous, current) {
        return current is ProjectDetailInitial ||
            current is ProjectDetailLoadInProgress ||
            current is ProjectDetailInitialDataLoadSuccess ||
            current is ProjectDetailLoadSuccess;
      },
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loadInProgress: () =>
              const Center(child: CircularProgressIndicator()),
          initialDataLoadSuccess: (availableValues) {
            return ProjectForm(
              initialData: null,
              formKey: _formKey,
              availableValues: availableValues,
              onSubmit: () {
                final formValues = validateAndGetFormValues(_formKey);
                if (formValues == null) return;

                final name = extractStringValue(formValues, 'name').trim();
                final description = extractNullableStringValue(
                  formValues,
                  'description',
                );
                final completed = extractBoolValue(formValues, 'completed');

                final repeatCandidate = extractNullableStringValue(
                  formValues,
                  'repeatIcalRrule',
                );
                final repeatIcalRrule =
                    (repeatCandidate == null || repeatCandidate.isEmpty)
                    ? null
                    : repeatCandidate;
                final startDate = extractDateTimeValue(formValues, 'startDate');
                final deadlineDate = extractDateTimeValue(
                  formValues,
                  'deadlineDate',
                );
                final valueIds = extractStringListValue(formValues, 'valueIds');

                context.read<ProjectDetailBloc>().add(
                  ProjectDetailEvent.create(
                    name: name,
                    description: description,
                    completed: completed,
                    startDate: startDate,
                    deadlineDate: deadlineDate,
                    repeatIcalRrule: repeatIcalRrule,
                    valueIds: valueIds,
                  ),
                );
              },
              submitTooltip: context.l10n.actionCreate,
              onClose: () => unawaited(closeEditor(context)),
            );
          },
          loadSuccess: (availableValues, project) {
            return ProjectForm(
              initialData: project,
              formKey: _formKey,
              availableValues: availableValues,
              onSubmit: () {
                final formValues = validateAndGetFormValues(_formKey);
                if (formValues == null) return;

                final name = extractStringValue(formValues, 'name').trim();
                final description = extractNullableStringValue(
                  formValues,
                  'description',
                );
                final completed = extractBoolValue(formValues, 'completed');

                final repeatCandidate = extractNullableStringValue(
                  formValues,
                  'repeatIcalRrule',
                );
                final repeatIcalRrule =
                    (repeatCandidate == null || repeatCandidate.isEmpty)
                    ? null
                    : repeatCandidate;
                final startDate = extractDateTimeValue(formValues, 'startDate');
                final deadlineDate = extractDateTimeValue(
                  formValues,
                  'deadlineDate',
                );
                final valueIds = extractStringListValue(formValues, 'valueIds');

                context.read<ProjectDetailBloc>().add(
                  ProjectDetailEvent.update(
                    id: project.id,
                    name: name,
                    description: description,
                    completed: completed,
                    startDate: startDate,
                    deadlineDate: deadlineDate,
                    repeatIcalRrule: repeatIcalRrule,
                    valueIds: valueIds,
                  ),
                );
              },
              onDelete: () async {
                final confirmed = await showDeleteConfirmationDialog(
                  context: context,
                  title: context.l10n.deleteProjectAction,
                  itemName: project.name,
                  description: context.l10n.deleteProjectCascadeDescription,
                );
                if (confirmed && context.mounted) {
                  context.read<ProjectDetailBloc>().add(
                    ProjectDetailEvent.delete(id: project.id),
                  );
                }
              },
              submitTooltip: context.l10n.actionUpdate,
              onClose: () => unawaited(closeEditor(context)),
            );
          },
          operationSuccess: (_) => const SizedBox.shrink(),
          operationFailure: (_) => const SizedBox.shrink(),
        );
      },
    );
  }
}

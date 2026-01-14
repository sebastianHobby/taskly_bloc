// drift types are provided by the generated database import below
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/domain/domain.dart';
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

  ProjectDraft _draft = ProjectDraft.empty();

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
            current is ProjectDetailValidationFailure ||
            current is ProjectDetailOperationFailure ||
            current is ProjectDetailLoadSuccess;
      },
      listener: (context, state) {
        state.mapOrNull(
          operationSuccess: (success) {
            unawaited(
              handleEditorOperationSuccess(
                context,
                operation: success.operation,
                createdMessage: context.l10n.projectCreatedSuccessfully,
                updatedMessage: context.l10n.projectUpdatedSuccessfully,
                deletedMessage: context.l10n.projectDeletedSuccessfully,
                onSaved: widget.projectId != null
                    ? () => widget.onSaved?.call(widget.projectId!)
                    : null,
              ),
            );
          },
          validationFailure: (failure) {
            applyValidationFailureToForm(_formKey, failure.failure, context);
          },
          operationFailure: (failure) {
            showEditorErrorSnackBar(context, failure.errorDetails.error);
          },
        );
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
            void syncDraft(Map<String, dynamic> values) {
              final name = extractStringValue(values, ProjectFieldKeys.name.id);
              final description = extractNullableStringValue(
                values,
                ProjectFieldKeys.description.id,
              );
              final completed = extractBoolValue(
                values,
                ProjectFieldKeys.completed.id,
              );
              final startDate = extractDateTimeValue(
                values,
                ProjectFieldKeys.startDate.id,
              );
              final deadlineDate = extractDateTimeValue(
                values,
                ProjectFieldKeys.deadlineDate.id,
              );
              final priority = values[ProjectFieldKeys.priority.id] as int?;
              final repeatCandidate = extractNullableStringValue(
                values,
                ProjectFieldKeys.repeatIcalRrule.id,
              );
              final repeatIcalRrule =
                  (repeatCandidate == null || repeatCandidate.isEmpty)
                  ? null
                  : repeatCandidate;
              final valueIds = extractStringListValue(
                values,
                ProjectFieldKeys.valueIds.id,
              );

              _draft = _draft.copyWith(
                name: name,
                description: description,
                completed: completed,
                startDate: startDate,
                deadlineDate: deadlineDate,
                priority: priority,
                repeatIcalRrule: repeatIcalRrule,
                valueIds: valueIds,
              );
            }

            _draft = ProjectDraft.empty();
            return ProjectForm(
              initialData: null,
              formKey: _formKey,
              availableValues: availableValues,
              onChanged: syncDraft,
              onSubmit: () {
                final formValues = validateAndGetFormValues(_formKey);
                if (formValues == null) return;

                syncDraft(formValues);

                context.read<ProjectDetailBloc>().add(
                  ProjectDetailEvent.create(
                    command: CreateProjectCommand(
                      name: _draft.name,
                      description: _draft.description,
                      completed: _draft.completed,
                      startDate: _draft.startDate,
                      deadlineDate: _draft.deadlineDate,
                      priority: _draft.priority,
                      repeatIcalRrule: _draft.repeatIcalRrule,
                      valueIds: _draft.valueIds,
                    ),
                  ),
                );
              },
              submitTooltip: context.l10n.actionCreate,
              onClose: () => unawaited(closeEditor(context)),
            );
          },
          loadSuccess: (availableValues, project) {
            void syncDraft(Map<String, dynamic> values) {
              final name = extractStringValue(values, ProjectFieldKeys.name.id);
              final description = extractNullableStringValue(
                values,
                ProjectFieldKeys.description.id,
              );
              final completed = extractBoolValue(
                values,
                ProjectFieldKeys.completed.id,
              );
              final startDate = extractDateTimeValue(
                values,
                ProjectFieldKeys.startDate.id,
              );
              final deadlineDate = extractDateTimeValue(
                values,
                ProjectFieldKeys.deadlineDate.id,
              );
              final priority = values[ProjectFieldKeys.priority.id] as int?;
              final repeatCandidate = extractNullableStringValue(
                values,
                ProjectFieldKeys.repeatIcalRrule.id,
              );
              final repeatIcalRrule =
                  (repeatCandidate == null || repeatCandidate.isEmpty)
                  ? null
                  : repeatCandidate;
              final valueIds = extractStringListValue(
                values,
                ProjectFieldKeys.valueIds.id,
              );

              _draft = _draft.copyWith(
                name: name,
                description: description,
                completed: completed,
                startDate: startDate,
                deadlineDate: deadlineDate,
                priority: priority,
                repeatIcalRrule: repeatIcalRrule,
                valueIds: valueIds,
              );
            }

            _draft = ProjectDraft.fromProject(project);
            return ProjectForm(
              initialData: project,
              formKey: _formKey,
              availableValues: availableValues,
              onChanged: syncDraft,
              onSubmit: () {
                final formValues = validateAndGetFormValues(_formKey);
                if (formValues == null) return;

                syncDraft(formValues);

                context.read<ProjectDetailBloc>().add(
                  ProjectDetailEvent.update(
                    command: UpdateProjectCommand(
                      id: project.id,
                      name: _draft.name,
                      description: _draft.description,
                      completed: _draft.completed,
                      startDate: _draft.startDate,
                      deadlineDate: _draft.deadlineDate,
                      priority: _draft.priority,
                      repeatIcalRrule: _draft.repeatIcalRrule,
                      valueIds: _draft.valueIds,
                    ),
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
          validationFailure: (_) => const SizedBox.shrink(),
        );
      },
    );
  }
}

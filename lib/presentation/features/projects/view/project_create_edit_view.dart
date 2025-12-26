// drift types are provided by the generated database import below
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/mixins/form_submission_mixin.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_form.dart';

class ProjectEditSheetPage extends StatelessWidget {
  const ProjectEditSheetPage({
    required this.projectRepository,
    required this.labelRepository,
    this.projectId,
    this.onSaved,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;
  final String? projectId;

  /// Optional callback when a project is saved (created or updated).
  /// Called with the project ID after successful save.
  final void Function(String projectId)? onSaved;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectDetailBloc(
        projectRepository: projectRepository,
        labelRepository: labelRepository,
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
      bloc.add(ProjectDetailEvent.get(projectId: projectId));
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
                'labelIds': project.labels
                    .map((l) => l.id)
                    .toList(growable: false),
              });
            });
          case ProjectDetailOperationSuccess(:final operation):
            final message = switch (operation) {
              EntityOperation.create => context.l10n.projectCreatedSuccessfully,
              EntityOperation.update => context.l10n.projectUpdatedSuccessfully,
              EntityOperation.delete => context.l10n.projectDeletedSuccessfully,
            };
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            // Call onSaved callback if provided (for edit scenarios that need refresh)
            if (widget.projectId != null) {
              widget.onSaved?.call(widget.projectId!);
            }
            unawaited(Navigator.of(context).maybePop());
          case ProjectDetailOperationFailure(:final errorDetails):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  friendlyErrorMessageForUi(errorDetails.error, context.l10n),
                ),
              ),
            );
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
          initialDataLoadSuccess: (availableLabels) {
            return ProjectForm(
              initialData: null,
              formKey: _formKey,
              availableLabels: availableLabels,
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
                final labelIds = extractStringListValue(formValues, 'labelIds');
                final selectedLabels = availableLabels
                    .where((l) => labelIds.contains(l.id))
                    .toList(growable: false);

                context.read<ProjectDetailBloc>().add(
                  ProjectDetailEvent.create(
                    name: name,
                    description: description,
                    completed: completed,
                    startDate: startDate,
                    deadlineDate: deadlineDate,
                    repeatIcalRrule: repeatIcalRrule,
                    labels: selectedLabels,
                  ),
                );
              },
              submitTooltip: context.l10n.actionCreate,
              onClose: () => Navigator.of(context).maybePop(),
            );
          },
          loadSuccess: (availableLabels, project) {
            return ProjectForm(
              initialData: project,
              formKey: _formKey,
              availableLabels: availableLabels,
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
                final labelIds = extractStringListValue(formValues, 'labelIds');
                final selectedLabels = availableLabels
                    .where((l) => labelIds.contains(l.id))
                    .toList(growable: false);

                context.read<ProjectDetailBloc>().add(
                  ProjectDetailEvent.update(
                    id: project.id,
                    name: name,
                    description: description,
                    completed: completed,
                    startDate: startDate,
                    deadlineDate: deadlineDate,
                    repeatIcalRrule: repeatIcalRrule,
                    labels: selectedLabels,
                  ),
                );
              },
              onDelete: () async {
                final confirmed = await showDeleteConfirmationDialog(
                  context: context,
                  title: 'Delete Project',
                  itemName: project.name,
                  description:
                      'All tasks in this project will also be deleted. This action cannot be undone.',
                );
                if (confirmed && context.mounted) {
                  context.read<ProjectDetailBloc>().add(
                    ProjectDetailEvent.delete(id: project.id),
                  );
                }
              },
              submitTooltip: context.l10n.actionUpdate,
              onClose: () => Navigator.of(context).maybePop(),
            );
          },
          operationSuccess: (_) => const SizedBox.shrink(),
          operationFailure: (_) => const SizedBox.shrink(),
        );
      },
    );
  }
}

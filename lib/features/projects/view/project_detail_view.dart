// drift types are provided by the generated database import below
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_form.dart';

class ProjectDetailSheetPage extends StatelessWidget {
  const ProjectDetailSheetPage({
    required this.projectRepository,
    required this.valueRepository,
    required this.labelRepository,
    required this.onSuccess,
    required this.onError,
    this.projectId,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final LabelRepositoryContract labelRepository;
  final String? projectId;
  final void Function(String message) onSuccess;
  final void Function(String message) onError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => ProjectDetailBloc(
          projectRepository: projectRepository,
          valueRepository: valueRepository,
          labelRepository: labelRepository,
        ),
        lazy: false,
        child: ProjectDetailSheetView(
          projectId: projectId,
          onSuccess: onSuccess,
          onError: onError,
        ),
      ),
    );
  }
}

class ProjectDetailSheetView extends StatefulWidget {
  const ProjectDetailSheetView({
    required this.onSuccess,
    required this.onError,
    this.projectId,
    super.key,
  });

  final String? projectId;
  final void Function(String message) onSuccess;
  final void Function(String message) onError;

  @override
  State<ProjectDetailSheetView> createState() => _ProjectDetailSheetViewState();
}

class _ProjectDetailSheetViewState extends State<ProjectDetailSheetView> {
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
            current is ProjectDetailOperationFailure;
      },
      listener: (context, state) {
        switch (state) {
          case ProjectDetailOperationSuccess(:final message):
            widget.onSuccess(message);
          case ProjectDetailOperationFailure(:final errorDetails):
            widget.onError(
              friendlyErrorMessageForUi(errorDetails.error, context.l10n),
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
          initialDataLoadSuccess: (availableValues, availableLabels) {
            return ProjectForm(
              initialData: null,
              formKey: _formKey,
              availableValues: availableValues,
              availableLabels: availableLabels,
              onSubmit: () {
                final formState = _formKey.currentState;
                if (formState == null) return;
                if (!formState.saveAndValidate()) return;

                final formValues = formState.value;
                final name = (formValues['name'] as String).trim();
                final completed = formValues['completed'] as bool? ?? false;

                final valueIds =
                    (formValues['valueIds'] as List<dynamic>?)
                        ?.cast<String>() ??
                    <String>[];
                final labelIds =
                    (formValues['labelIds'] as List<dynamic>?)
                        ?.cast<String>() ??
                    <String>[];

                final selectedValues = availableValues
                    .where((v) => valueIds.contains(v.id))
                    .toList(growable: false);
                final selectedLabels = availableLabels
                    .where((l) => labelIds.contains(l.id))
                    .toList(growable: false);

                context.read<ProjectDetailBloc>().add(
                  ProjectDetailEvent.create(
                    name: name,
                    completed: completed,
                    values: selectedValues,
                    labels: selectedLabels,
                  ),
                );
              },
              submitTooltip: 'Create',
            );
          },
          loadSuccess: (availableValues, availableLabels, project) {
            return ProjectForm(
              initialData: project,
              formKey: _formKey,
              availableValues: availableValues,
              availableLabels: availableLabels,
              onSubmit: () {
                final formState = _formKey.currentState;
                if (formState == null) return;
                if (!formState.saveAndValidate()) return;

                final formValues = formState.value;
                final name = (formValues['name'] as String).trim();
                final completed = formValues['completed'] as bool? ?? false;

                final valueIds =
                    (formValues['valueIds'] as List<dynamic>?)
                        ?.cast<String>() ??
                    <String>[];
                final labelIds =
                    (formValues['labelIds'] as List<dynamic>?)
                        ?.cast<String>() ??
                    <String>[];

                final selectedValues = availableValues
                    .where((v) => valueIds.contains(v.id))
                    .toList(growable: false);
                final selectedLabels = availableLabels
                    .where((l) => labelIds.contains(l.id))
                    .toList(growable: false);

                context.read<ProjectDetailBloc>().add(
                  ProjectDetailEvent.update(
                    id: project.id,
                    name: name,
                    completed: completed,
                    values: selectedValues,
                    labels: selectedLabels,
                  ),
                );
              },
              submitTooltip: 'Update',
            );
          },
          operationSuccess: (_) => const SizedBox.shrink(),
          operationFailure: (_) => const SizedBox.shrink(),
        );
      },
    );
  }
}

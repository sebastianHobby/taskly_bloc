// drift types are provided by the generated database import below
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/data/repositories/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_form.dart';

class ProjectDetailSheetPage extends StatelessWidget {
  const ProjectDetailSheetPage({
    required this.projectRepository,
    required this.onSuccess,
    required this.onError,
    this.projectId,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final String? projectId;
  final void Function(String message) onSuccess;
  final void Function(String message) onError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => ProjectDetailBloc(
          projectRepository: projectRepository,
          projectId: projectId,
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

  void _onSubmit(String? id) {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (formState.saveAndValidate()) {
      final formValues = formState.value;
      if (id == null) {
        // Create new data
        context.read<ProjectDetailBloc>().add(
          ProjectDetailEvent.create(
            name: formValues['name'] as String,
          ),
        );
      } else {
        // Update existing data
        context.read<ProjectDetailBloc>().add(
          ProjectDetailEvent.update(
            id: id,
            name: formValues['name'] as String,
            completed: formValues['completed'] as bool,
          ),
        );
      }
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
            widget.onError(errorDetails.message);
          default:
            return;
        }
      },
      buildWhen: (previous, current) {
        return current is ProjectDetailInitial ||
            current is ProjectDetailLoadInProgress ||
            current is ProjectDetailLoadSuccess;
      },
      builder: (context, state) {
        switch (state) {
          case ProjectDetailInitial():
            return ProjectForm(
              initialData: null,
              formKey: _formKey,
              onSubmit: () => _onSubmit(widget.projectId),
              submitTooltip: 'Create',
            );
          case ProjectDetailLoadInProgress():
            return const Center(child: CircularProgressIndicator());
          case ProjectDetailLoadSuccess(:final project):
            return ProjectForm(
              initialData: project,
              formKey: _formKey,
              onSubmit: () => _onSubmit(project.id),
              submitTooltip: 'Update',
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

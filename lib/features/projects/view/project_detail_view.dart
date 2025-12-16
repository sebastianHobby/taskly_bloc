import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_form_item.dart';

enum ProjectDetailMode { create, edit }

class ProjectDetailPage extends StatelessWidget {
  ProjectDetailPage({this.projectId, super.key});
  final ProjectRepository projectRepository = getIt<ProjectRepository>();
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectDetailBloc(
        projectRepository: projectRepository,
        projectId: projectId,
      ),
      child: ProjectDetailView(),
    );
  }
}

class ProjectDetailView extends StatefulWidget {
  const ProjectDetailView({super.key});

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<ProjectDetailView> {
  // Create a global key that uniquely identifies the Form widget
  final _formKey = GlobalKey<FormBuilderState>();

  // cache initial values derived from the companion
  late final Map<String, dynamic> _initialValues;

  Map<String, dynamic> _companionToInitialFormValues(
    ProjectTableCompanion companion,
  ) {
    return <String, dynamic>{
      'name': companion.name.present ? companion.name.value : '',
      'description': companion.description.present
          ? companion.description.value
          : '',
      'completed': companion.completed.present && companion.completed.value,
    };
  }

  Future<void> onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.isDirty) {
      Navigator.pop(context);
      return;
    }

    final shouldPop = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if ((shouldPop ?? false) && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildError(String message, StackTrace stacktrace) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Error: $message', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              stacktrace.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreate() {
    void onSubmitCreate() {
      final formState = _formKey.currentState;
      if (formState == null) return;
      if (formState.saveAndValidate()) {
        final name = (formState.value['name'] as String?)?.trim() ?? '';
        final description =
            (formState.value['description'] as String?)?.trim() ?? '';
        final completed = formState.value['completed'] as bool? ?? false;

        final createCompanion = ProjectTableCompanion(
          name: Value(name),
          description: Value(description),
          completed: Value(completed),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        );

        context.read<ProjectDetailBloc>().add(
          ProjectDetailEvent.createProject(createCompanion: createCompanion),
        );

        Navigator.pop(context);
      }
    }

    final body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: FormBuilder(
        key: _formKey,
        initialValue: _initialValues,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ProjectFormItem(initialValues: _initialValues),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: onPopInvoked,
      child: SheetKeyboardDismissible(
        dismissBehavior: const SheetKeyboardDismissBehavior.onDragDown(
          isContentScrollAware: true,
        ),
        child: Sheet(
          scrollConfiguration: const SheetScrollConfiguration(),
          decoration: MaterialSheetDecoration(
            size: SheetSize.stretch,
            color: Theme.of(context).colorScheme.secondaryContainer,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          child: SheetContentScaffold(
            body: body,
            bottomBar: Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: SafeArea(
                top: false,
                child: SizedBox.fromSize(
                  size: const Size.fromHeight(kToolbarHeight),
                  child: Row(
                    children: [
                      IconButton.filled(
                        icon: const Icon(Icons.check),
                        tooltip: 'Submit',
                        onPressed: onSubmitCreate,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdit() => const Center(child: CircularProgressIndicator());

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectDetailBloc, ProjectDetailState>(
      builder: (context, state) {
        return state.when(
          loading: _buildLoading,
          createProject: _buildCreate,
          editProject: _buildEdit,
          error: _buildError,
        );
      },
    );
  }
}

// ignore_for_file: avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/dtos/projects/project_dto.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/features/projects/models/project_models.dart';

enum Priority {
  high(displayName: 'High Priority', color: Colors.red),
  medium(displayName: 'Medium Priority', color: Colors.orange),
  low(displayName: 'Low Priority', color: Colors.blue),
  none(displayName: 'No Priority');

  const Priority({
    required this.displayName,
    this.color,
  });

  final String displayName;
  final Color? color;
}

class ProjectDetailPage extends StatelessWidget {
  ProjectDetailPage({super.key, this.projectDto});
  final ProjectRepository projectRepository = getIt<ProjectRepository>();
  final ProjectDto? projectDto;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectDetailBloc(projectRepository: projectRepository),
      child: ProjectDetailView(
        projectDto: projectDto,
      ),
    );
  }
}

class ProjectDetailView extends StatefulWidget {
  const ProjectDetailView({super.key, this.projectDto});
  final ProjectDto? projectDto;

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<ProjectDetailView> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  ProjectDto? get _projectDto => widget.projectDto;

  // Controllers and local state for detecting changes
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _projectDto?.name ?? '');
    _descriptionController = TextEditingController(
      text: _projectDto?.description ?? '',
    );
    _completed = _projectDto?.completed ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Returns true if the current form values differ from the initial values.
  bool _hasFormChanged() {
    final initialName = _projectDto?.name ?? '';
    final initialDescription = _projectDto?.description ?? '';
    final initialCompleted = _projectDto?.completed ?? false;

    if (_nameController.text.trim() != initialName.trim()) return true;
    if (_descriptionController.text != initialDescription) return true;
    if (_completed != initialCompleted) return true;
    return false;
  }

  String? requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    return null;
  }

  ProjectDto? get projectDto => widget.projectDto;

  Future<void> onPopInvokedWithResult(bool didPop, Object? result) async {
    if (didPop) {
      // Already popped.
      return;
    }
    if (!_hasFormChanged()) {
      Navigator.pop(context);
      return;
    }

    // Show a confirmation dialog.
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

  @override
  Widget build(BuildContext context) {
    final projectNameInput = TextFormField(
      controller: _nameController,
      autofocus: true,
      style: Theme.of(context).textTheme.titleLarge,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: const InputDecoration(
        hintText: 'Title',
        border: InputBorder.none,
      ),
      validator: requiredValidator,
    );

    final projectDescriptionInput = TextFormField(
      controller: _descriptionController,
      style: Theme.of(context).textTheme.bodyLarge,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: const InputDecoration(
        hintText: 'Description',
        border: InputBorder.none,
      ),
    );

    // Build a Form widget using the _formKey created above.
    final body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: projectNameInput,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: projectDescriptionInput,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false otherwise.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // If projectDto exists then this is an update else create new project
                    if (_projectDto != null) {
                      final ProjectActionRequestUpdate updateRequest =
                          ProjectActionRequestUpdate(
                            projectToUpdate: _projectDto!,
                            name: _nameController.text,
                            description: _descriptionController.text,
                            completed: _projectDto!.completed,
                          );
                      context.read<ProjectDetailBloc>().add(
                        ProjectDetailEvent.updateProject(
                          updateRequest: updateRequest,
                        ),
                      );
                    } else {
                      final ProjectActionRequestCreate createRequest =
                          ProjectActionRequestCreate(
                            name: _nameController.text,
                            completed: false,
                            description: _descriptionController.text,
                          );
                      context.read<ProjectDetailBloc>().add(
                        ProjectDetailEvent.createProject(
                          createRequest: createRequest,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: onPopInvokedWithResult,
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
            // bottomBarVisibility: const BottomBarVisibility.always(
            //   // Make the bottom bar visible when the keyboard is open.
            //   ignoreBottomInset: true,
            // ),
            body: body,
            // bottomBar: bottomBar,
          ),
        ),
      ),
    );
  }
}

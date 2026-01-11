import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/entity_selector.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/data_list_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/screens/language/models/trigger_config.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_icon_picker.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_trigger_config.dart';
import 'package:uuid/uuid.dart';

/// Page for creating or editing workflow definitions.
///
/// Uses FormBuilder for form state management and validation.
class WorkflowCreatorPage extends StatefulWidget {
  const WorkflowCreatorPage({
    required this.workflowRepository,
    required this.userId,
    this.existingWorkflow,
    super.key,
  });

  final WorkflowRepositoryContract workflowRepository;
  final String userId;

  /// If provided, editing an existing workflow.
  final WorkflowDefinition? existingWorkflow;

  bool get isEditing => existingWorkflow != null;

  @override
  State<WorkflowCreatorPage> createState() => _WorkflowCreatorPageState();
}

class _WorkflowCreatorPageState extends State<WorkflowCreatorPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  late List<WorkflowStepFormData> _steps;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _steps =
        widget.existingWorkflow?.steps
            .map(WorkflowStepFormData.fromStep)
            .toList() ??
        [WorkflowStepFormData.empty()];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Workflow' : 'Create Workflow'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: FormBuilder(
        key: _formKey,
        initialValue: _initialValues,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Section
            _SectionHeader(title: 'Basic Info'),
            const SizedBox(height: 8),
            FormBuilderTextField(
              name: 'name',
              decoration: const InputDecoration(
                labelText: 'Workflow Name',
                hintText: 'e.g., Weekly Review',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(2),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'description',
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What this workflow helps you accomplish',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Icon Section
            _SectionHeader(title: 'Icon'),
            const SizedBox(height: 8),
            FormBuilderIconPicker(
              name: 'iconName',
            ),
            const SizedBox(height: 24),

            // Schedule Section
            _SectionHeader(title: 'Schedule'),
            const SizedBox(height: 8),
            Text(
              'How often should this workflow run?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FormBuilderTriggerConfig(
              name: 'triggerConfig',
            ),
            const SizedBox(height: 24),

            // Steps Section
            _SectionHeader(
              title: 'Steps',
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addStep,
                tooltip: 'Add step',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Define the steps of your workflow. Each step shows a view of entities to review.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              onReorder: _reorderSteps,
              itemBuilder: (context, index) {
                return _StepCard(
                  key: ValueKey(_steps[index].id),
                  step: _steps[index],
                  index: index,
                  canDelete: _steps.length > 1,
                  onChanged: (updated) => _updateStep(index, updated),
                  onDelete: () => _deleteStep(index),
                );
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                widget.isEditing ? 'Save Changes' : 'Create Workflow',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> get _initialValues {
    final existing = widget.existingWorkflow;
    if (existing == null) {
      return {
        'name': '',
        'description': '',
        'iconName': 'rate_review',
        'triggerConfig': const TriggerConfig.manual(),
      };
    }
    return {
      'name': existing.name,
      'description': existing.description ?? '',
      'iconName': existing.iconName ?? 'rate_review',
      'triggerConfig': existing.triggerConfig ?? const TriggerConfig.manual(),
    };
  }

  void _addStep() {
    setState(() {
      _steps.add(WorkflowStepFormData.empty());
    });
  }

  void _updateStep(int index, WorkflowStepFormData updated) {
    setState(() {
      _steps[index] = updated;
    });
  }

  void _deleteStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      var insertIndex = newIndex;
      if (insertIndex > oldIndex) insertIndex--;
      final step = _steps.removeAt(oldIndex);
      _steps.insert(insertIndex, step);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }

    // Validate steps
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one step')),
      );
      return;
    }

    for (final step in _steps) {
      if (step.name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All steps must have a name')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final values = _formKey.currentState!.value;
      final now = DateTime.now();

      final workflowSteps = _steps
          .asMap()
          .entries
          .map(
            (entry) => WorkflowStep(
              id: entry.value.id,
              name: entry.value.name,
              order: entry.key,
              sections: entry.value.toSections(),
            ),
          )
          .toList();

      if (widget.isEditing) {
        final updated = widget.existingWorkflow!.copyWith(
          name: values['name'] as String,
          description:
              (values['description'] as String?)?.trim().isEmpty ?? false
              ? null
              : values['description'] as String?,
          iconName: values['iconName'] as String?,
          triggerConfig: values['triggerConfig'] as TriggerConfig?,
          steps: workflowSteps,
          updatedAt: now,
        );
        await widget.workflowRepository.updateWorkflowDefinition(updated);
      } else {
        final workflow = WorkflowDefinition(
          id: '', // Repository generates v5 ID
          name: values['name'] as String,
          description:
              (values['description'] as String?)?.trim().isEmpty ?? false
              ? null
              : values['description'] as String?,
          iconName: values['iconName'] as String?,
          steps: workflowSteps,
          triggerConfig: values['triggerConfig'] as TriggerConfig?,
          createdAt: now,
          updatedAt: now,
        );
        await widget.workflowRepository.createWorkflowDefinition(workflow);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      talker.handle(e, st, '[WorkflowCreatorPage] Save error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workflow: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workflow'),
        content: Text(
          'Are you sure you want to delete "${widget.existingWorkflow!.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      try {
        await widget.workflowRepository.deleteWorkflowDefinition(
          widget.existingWorkflow!.id,
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting workflow: $e')),
          );
        }
      }
    }
  }
}

// =============================================================================
// Supporting Widgets
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

// =============================================================================
// Step Form Data
// =============================================================================

/// Mutable form data for a workflow step.
class WorkflowStepFormData {
  WorkflowStepFormData({
    required this.id,
    required this.name,
    required this.entityType,
  });

  factory WorkflowStepFormData.empty() {
    return WorkflowStepFormData(
      id: const Uuid().v4(),
      name: '',
      entityType: EntityType.task,
    );
  }

  factory WorkflowStepFormData.fromStep(WorkflowStep step) {
    // Extract entity type from the first supported list template.
    var entityType = EntityType.task;
    for (final section in step.sections) {
      entityType = switch (section.templateId) {
        SectionTemplateId.taskList => EntityType.task,
        SectionTemplateId.projectList => EntityType.project,
        SectionTemplateId.valueList => EntityType.value,
        SectionTemplateId.journalTimeline => EntityType.journal,
        _ => entityType,
      };

      if (section.templateId == SectionTemplateId.taskList ||
          section.templateId == SectionTemplateId.projectList ||
          section.templateId == SectionTemplateId.valueList ||
          section.templateId == SectionTemplateId.journalTimeline) {
        break;
      }
    }
    return WorkflowStepFormData(
      id: step.id,
      name: step.name,
      entityType: entityType,
    );
  }

  final String id;
  String name;
  EntityType entityType;

  WorkflowStepFormData copyWith({
    String? name,
    EntityType? entityType,
  }) {
    return WorkflowStepFormData(
      id: id,
      name: name ?? this.name,
      entityType: entityType ?? this.entityType,
    );
  }

  List<SectionRef> toSections() {
    const display = DisplayConfig(
      showCompleted: false,
      sorting: [
        SortCriterion(
          field: SortField.updatedAt,
          direction: SortDirection.desc,
        ),
      ],
    );

    return switch (entityType) {
      EntityType.task => [
        SectionRef(
          templateId: SectionTemplateId.taskList,
          params: DataListSectionParams(
            config: DataConfig.task(query: const TaskQuery()),
            taskTileVariant: TaskTileVariant.listTile,
            projectTileVariant: ProjectTileVariant.listTile,
            valueTileVariant: ValueTileVariant.compactCard,
            display: display,
          ).toJson(),
        ),
      ],
      EntityType.project => [
        SectionRef(
          templateId: SectionTemplateId.projectList,
          params: DataListSectionParams(
            config: DataConfig.project(query: const ProjectQuery()),
            taskTileVariant: TaskTileVariant.listTile,
            projectTileVariant: ProjectTileVariant.listTile,
            valueTileVariant: ValueTileVariant.compactCard,
            display: display,
          ).toJson(),
        ),
      ],
      EntityType.value => [
        SectionRef(
          templateId: SectionTemplateId.valueList,
          params: DataListSectionParams(
            config: DataConfig.value(query: const ValueQuery()),
            taskTileVariant: TaskTileVariant.listTile,
            projectTileVariant: ProjectTileVariant.listTile,
            valueTileVariant: ValueTileVariant.compactCard,
            display: display,
          ).toJson(),
        ),
      ],
      // Workflows currently support review of lists (task/project/value).
      // For other entity types, fall back to a task list until a dedicated
      // template is introduced.
      EntityType.journal => const [
        SectionRef(templateId: SectionTemplateId.journalTimeline),
      ],
      _ => [
        SectionRef(
          templateId: SectionTemplateId.taskList,
          params: DataListSectionParams(
            config: DataConfig.task(query: const TaskQuery()),
            taskTileVariant: TaskTileVariant.listTile,
            projectTileVariant: ProjectTileVariant.listTile,
            valueTileVariant: ValueTileVariant.compactCard,
            display: display,
          ).toJson(),
        ),
      ],
    };
  }
}

// =============================================================================
// Step Card Widget
// =============================================================================

class _StepCard extends StatelessWidget {
  const _StepCard({
    required super.key,
    required this.step,
    required this.index,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final WorkflowStepFormData step;
  final int index;
  final bool canDelete;
  final ValueChanged<WorkflowStepFormData> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                // Step number
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.name.isEmpty ? 'Step ${index + 1}' : step.name,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDelete,
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Step name input
            TextFormField(
              initialValue: step.name,
              decoration: const InputDecoration(
                labelText: 'Step Name',
                hintText: 'e.g., Review Projects',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => onChanged(step.copyWith(name: value)),
            ),
            const SizedBox(height: 12),

            // Entity type selector
            DropdownButtonFormField<EntityType>(
              initialValue: step.entityType,
              decoration: const InputDecoration(
                labelText: 'Review Type',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: EntityType.task,
                  child: Text('Tasks'),
                ),
                DropdownMenuItem(
                  value: EntityType.project,
                  child: Text('Projects'),
                ),
                DropdownMenuItem(
                  value: EntityType.goal,
                  child: Text('Values/Goals'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(step.copyWith(entityType: value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

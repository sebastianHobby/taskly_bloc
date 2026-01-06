import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_icon_picker.dart';

/// Entity type options for the screen creator
enum EntityTypeOption {
  task('Tasks', Icons.check_box_outlined),
  project('Projects', Icons.folder_outlined),
  value('Values', Icons.star_outlined);

  const EntityTypeOption(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}

/// Page for creating or editing screen definitions.
///
/// Uses FormBuilder for form state management and validation.
/// Supports basic data sections with entity type selection.
class ScreenCreatorPage extends StatefulWidget {
  const ScreenCreatorPage({
    required this.screensRepository,
    required this.userId,
    this.existingScreen,
    super.key,
  });

  /// Repository for persisting screen definitions.
  final ScreenDefinitionsRepositoryContract screensRepository;

  /// The user ID for the screen owner.
  final String userId;

  /// If provided, edits this existing screen instead of creating a new one.
  final ScreenDefinition? existingScreen;

  /// Whether we're editing an existing screen.
  bool get isEditing => existingScreen != null;

  @override
  State<ScreenCreatorPage> createState() => _ScreenCreatorPageState();
}

class _ScreenCreatorPageState extends State<ScreenCreatorPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Screen' : 'Create Screen'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Delete Screen',
            ),
        ],
      ),
      body: FormBuilder(
        key: _formKey,
        initialValue: _getInitialValues(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== Basic Info Section =====
            _SectionHeader(
              icon: Icons.info_outline,
              title: 'Basic Information',
            ),
            const SizedBox(height: 12),

            // Screen name
            FormBuilderTextField(
              name: 'name',
              decoration: const InputDecoration(
                labelText: 'Screen Name',
                hintText: 'e.g., "High Priority Tasks"',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(2),
                FormBuilderValidators.maxLength(50),
              ]),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Icon picker
            FormBuilderIconPicker(
              name: 'iconName',
              decoration: const InputDecoration(
                labelText: 'Icon',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            FormBuilderDropdown<ScreenCategory>(
              name: 'category',
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ScreenCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.displayName),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ===== Content Section =====
            _SectionHeader(
              icon: Icons.view_list,
              title: 'Content',
            ),
            const SizedBox(height: 12),

            // Entity type
            FormBuilderDropdown<EntityTypeOption>(
              name: 'entityType',
              decoration: const InputDecoration(
                labelText: 'What to Display',
                helperText: 'Select the type of items to show in this screen',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.required(),
              items: EntityTypeOption.values.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(e.icon, size: 20),
                      const SizedBox(width: 12),
                      Text(e.displayName),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ===== Display Options Section =====
            _SectionHeader(
              icon: Icons.tune,
              title: 'Display Options',
            ),
            const SizedBox(height: 12),

            // Show completed
            FormBuilderSwitch(
              name: 'showCompleted',
              title: const Text('Show Completed Items'),
              subtitle: const Text('Include completed tasks in the view'),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),

            // Show archived
            FormBuilderSwitch(
              name: 'showArchived',
              title: const Text('Show Archived Items'),
              subtitle: const Text('Include archived items in the view'),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),

            // ===== Sorting Section =====
            _SectionHeader(
              icon: Icons.sort,
              title: 'Sorting',
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FormBuilderDropdown<SortField>(
                    name: 'sortField',
                    decoration: const InputDecoration(
                      labelText: 'Sort By',
                      border: OutlineInputBorder(),
                    ),
                    items: SortField.values.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Text(_sortFieldDisplayName(f)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderDropdown<SortDirection>(
                    name: 'sortDirection',
                    decoration: const InputDecoration(
                      labelText: 'Direction',
                      border: OutlineInputBorder(),
                    ),
                    items: SortDirection.values.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(_sortDirectionDisplayName(d)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ===== Visibility Section =====
            _SectionHeader(
              icon: Icons.visibility,
              title: 'Visibility',
            ),
            const SizedBox(height: 12),

            FormBuilderSwitch(
              name: 'isActive',
              title: const Text('Active'),
              subtitle: const Text('Show this screen in navigation'),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveScreen,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Screen'),
            ),

            const SizedBox(height: 88), // Space for FAB
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getInitialValues() {
    if (widget.existingScreen case final screen?) {
      // Only DataDriven screens can be edited
      if (screen is! DataDrivenScreenDefinition) {
        return {
          'name': screen.name,
          'iconName': screen.iconName,
          'category': screen.category,
          'entityType': null,
          'groupBy': GroupByField.none,
          'sortField': SortField.updatedAt,
          'sortDirection': SortDirection.desc,
          'showCompleted': true,
          'showArchived': false,
        };
      }

      // Extract values from existing data-driven screen
      EntityTypeOption? entityType;
      GroupByField groupBy = GroupByField.none;
      SortField sortField = SortField.updatedAt;
      SortDirection sortDirection = SortDirection.desc;
      bool showCompleted = true;
      bool showArchived = false;

      final firstSection = screen.sections.isNotEmpty
          ? screen.sections.first
          : null;
      if (firstSection is DataSection) {
        // Determine entity type from config
        entityType = switch (firstSection.config) {
          TaskDataConfig() => EntityTypeOption.task,
          ProjectDataConfig() => EntityTypeOption.project,
          ValueDataConfig() => EntityTypeOption.value,
          JournalDataConfig() => null, // Journal editing not yet supported
        };

        // Extract display settings
        if (firstSection.display case final display?) {
          groupBy = display.groupBy;
          if (display.sorting.isNotEmpty) {
            sortField = display.sorting.first.field;
            sortDirection = display.sorting.first.direction;
          }
          showCompleted = display.showCompleted;
          showArchived = display.showArchived;
        }
      }

      return {
        'name': screen.name,
        'iconName': screen.iconName,
        'category': screen.category,
        'entityType': entityType,
        'groupBy': groupBy,
        'sortField': sortField,
        'sortDirection': sortDirection,
        'showCompleted': showCompleted,
        'showArchived': showArchived,
      };
    }

    // Default values for new screen
    return {
      'name': '',
      'iconName': null,
      'category': ScreenCategory.workspace,
      'entityType': EntityTypeOption.task,
      'groupBy': GroupByField.none,
      'sortField': SortField.updatedAt,
      'sortDirection': SortDirection.desc,
      'showCompleted': false,
      'showArchived': false,
    };
  }

  String _sortFieldDisplayName(SortField field) {
    return switch (field) {
      SortField.name => 'Name',
      SortField.deadlineDate => 'Due Date',
      SortField.startDate => 'Start Date',
      SortField.priority => 'Priority',
      SortField.createdAt => 'Created',
      SortField.updatedAt => 'Updated',
    };
  }

  String _sortDirectionDisplayName(SortDirection direction) {
    return switch (direction) {
      SortDirection.asc => 'Ascending',
      SortDirection.desc => 'Descending',
    };
  }

  Future<void> _saveScreen() async {
    if (_formKey.currentState?.saveAndValidate() != true) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final values = _formKey.currentState!.value;
      final now = DateTime.now();

      // Build display config
      final displayConfig = DisplayConfig(
        groupBy: values['groupBy'] as GroupByField? ?? GroupByField.none,
        sorting: [
          SortCriterion(
            field: values['sortField'] as SortField? ?? SortField.updatedAt,
            direction:
                values['sortDirection'] as SortDirection? ?? SortDirection.desc,
          ),
        ],
        showCompleted: values['showCompleted'] as bool? ?? false,
        showArchived: values['showArchived'] as bool? ?? false,
      );

      // Build data config based on entity type
      final entityType = values['entityType'] as EntityTypeOption;
      final dataConfig = switch (entityType) {
        EntityTypeOption.task => DataConfig.task(query: const TaskQuery()),
        EntityTypeOption.project => DataConfig.project(
          query: const ProjectQuery(),
        ),
        EntityTypeOption.value => const DataConfig.value(),
      };

      // Build the section
      final section = Section.data(
        config: dataConfig,
        display: displayConfig,
      );

      if (widget.isEditing) {
        final existing = widget.existingScreen!;
        if (existing is! DataDrivenScreenDefinition) {
          throw StateError('Cannot edit a non-data-driven screen');
        }
        final updated = existing.copyWith(
          name: values['name'] as String,
          iconName: values['iconName'] as String?,
          category: values['category'] as ScreenCategory,
          sections: [section],
          updatedAt: now,
        );
        await widget.screensRepository.updateCustomScreen(updated);
      } else {
        final screenKey = _generateScreenKey(values['name'] as String);

        // Validate screenKey uniqueness before creating
        final exists = await widget.screensRepository.screenKeyExists(
          screenKey,
        );
        if (exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'A screen with the key "$screenKey" already exists. '
                  'Please choose a different name.',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }

        final screen = ScreenDefinition.dataDriven(
          id: '', // Repository generates v5 ID based on screenKey
          screenKey: screenKey,
          name: values['name'] as String,
          screenType: ScreenType.list,
          iconName: values['iconName'] as String?,
          category: values['category'] as ScreenCategory,
          sections: [section],
          createdAt: now,
          updatedAt: now,
        );
        await widget.screensRepository.createCustomScreen(screen);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      talker.handle(e, st, '[ScreenCreatorPage] Error saving screen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving screen: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _generateScreenKey(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Screen'),
        content: Text(
          'Are you sure you want to delete "${widget.existingScreen!.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
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
        await widget.screensRepository.deleteCustomScreen(
          widget.existingScreen!.id,
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e, st) {
        talker.handle(e, st, '[ScreenCreatorPage] Error deleting screen');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting screen: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

/// Section header widget for organizing form fields
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

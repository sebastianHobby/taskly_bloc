import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_entity_type_picker.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_icon_picker.dart';

/// Page for creating or editing screen definitions.
///
/// Uses FormBuilder for form state management and validation.
/// Supports basic collection views with entity type selection.
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
            FormBuilderEntityTypePicker(
              name: 'entityType',
              decoration: const InputDecoration(
                labelText: 'What to Display',
                helperText: 'Select the type of items to show in this screen',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.required(),
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
              subtitle: const Text('Include archived projects and labels'),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),

            // Group by
            FormBuilderDropdown<GroupByField>(
              name: 'groupBy',
              decoration: const InputDecoration(
                labelText: 'Group By',
                border: OutlineInputBorder(),
              ),
              items: GroupByField.values.map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Text(_getGroupByLabel(g)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Sort by
            FormBuilderDropdown<SortField>(
              name: 'sortField',
              decoration: const InputDecoration(
                labelText: 'Sort By',
                border: OutlineInputBorder(),
              ),
              items: SortField.values.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(_getSortFieldLabel(s)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Sort direction
            FormBuilderDropdown<SortDirection>(
              name: 'sortDirection',
              decoration: const InputDecoration(
                labelText: 'Sort Direction',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: SortDirection.asc,
                  child: Text('Ascending'),
                ),
                DropdownMenuItem(
                  value: SortDirection.desc,
                  child: Text('Descending'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ===== Active Status =====
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FormBuilderSwitch(
                  name: 'isActive',
                  title: const Text('Active'),
                  subtitle: const Text(
                    'Inactive screens are hidden from navigation',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
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
      // Extract values from existing screen
      final view = screen.view;
      EntityType? entityType;
      GroupByField groupBy = GroupByField.none;
      SortField sortField = SortField.updatedAt;
      SortDirection sortDirection = SortDirection.desc;
      bool showCompleted = true;
      bool showArchived = false;

      if (view case CollectionView(:final selector, :final display)) {
        entityType = selector.entityType;
        groupBy = display.groupBy;
        if (display.sorting.isNotEmpty) {
          sortField = display.sorting.first.field;
          sortDirection = display.sorting.first.direction;
        }
        showCompleted = display.showCompleted;
        showArchived = display.showArchived;
      } else if (view case AgendaView(:final selector, :final display)) {
        entityType = selector.entityType;
        groupBy = display.groupBy;
        if (display.sorting.isNotEmpty) {
          sortField = display.sorting.first.field;
          sortDirection = display.sorting.first.direction;
        }
        showCompleted = display.showCompleted;
        showArchived = display.showArchived;
      }

      return {
        'name': screen.name,
        'iconName': screen.iconName,
        'category': screen.category,
        'entityType': entityType,
        'showCompleted': showCompleted,
        'showArchived': showArchived,
        'groupBy': groupBy,
        'sortField': sortField,
        'sortDirection': sortDirection,
        'isActive': screen.isActive,
      };
    }

    // Default values for new screen
    return {
      'name': '',
      'iconName': null,
      'category': ScreenCategory.workspace,
      'entityType': EntityType.task,
      'showCompleted': false,
      'showArchived': false,
      'groupBy': GroupByField.none,
      'sortField': SortField.updatedAt,
      'sortDirection': SortDirection.desc,
      'isActive': true,
    };
  }

  String _getGroupByLabel(GroupByField field) {
    switch (field) {
      case GroupByField.none:
        return 'None';
      case GroupByField.project:
        return 'Project';
      case GroupByField.value:
        return 'Value';
      case GroupByField.label:
        return 'Label';
      case GroupByField.date:
        return 'Date';
      case GroupByField.priority:
        return 'Priority';
    }
  }

  String _getSortFieldLabel(SortField field) {
    switch (field) {
      case SortField.name:
        return 'Name';
      case SortField.createdAt:
        return 'Created Date';
      case SortField.updatedAt:
        return 'Updated Date';
      case SortField.deadlineDate:
        return 'Deadline';
      case SortField.startDate:
        return 'Start Date';
      case SortField.priority:
        return 'Priority';
    }
  }

  Future<void> _saveScreen() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final values = _formKey.currentState!.value;
      final now = DateTime.now();

      // Build display config
      final displayConfig = DisplayConfig(
        groupBy: values['groupBy'] as GroupByField,
        sorting: [
          SortCriterion(
            field: values['sortField'] as SortField,
            direction: values['sortDirection'] as SortDirection,
          ),
        ],
        showCompleted: values['showCompleted'] as bool? ?? false,
        showArchived: values['showArchived'] as bool? ?? false,
      );

      // Build entity selector
      final entitySelector = EntitySelector(
        entityType: values['entityType'] as EntityType,
      );

      // Build view definition (simple collection view)
      final viewDefinition = ViewDefinition.collection(
        selector: entitySelector,
        display: displayConfig,
      );

      if (widget.isEditing) {
        final updated = widget.existingScreen!.copyWith(
          name: values['name'] as String,
          iconName: values['iconName'] as String?,
          category: values['category'] as ScreenCategory,
          view: viewDefinition,
          isActive: values['isActive'] as bool? ?? true,
          updatedAt: now,
        );
        await widget.screensRepository.updateScreen(updated);
      } else {
        final screen = ScreenDefinition(
          id: '', // Repository generates v5 ID based on screenKey
          screenKey: _generateScreenKey(values['name'] as String),
          name: values['name'] as String,
          iconName: values['iconName'] as String?,
          category: values['category'] as ScreenCategory,
          view: viewDefinition,
          isActive: values['isActive'] as bool? ?? true,
          sortOrder: 999, // Will be adjusted by the system
          createdAt: now,
          updatedAt: now,
        );
        await widget.screensRepository.createScreen(screen);
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

    if (confirmed ?? false) {
      await widget.screensRepository.deleteScreen(widget.existingScreen!.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }
}

// =============================================================================
// Section Header Widget
// =============================================================================

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
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

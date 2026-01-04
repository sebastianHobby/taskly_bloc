import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/next_action/widgets/persona_selection_card.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_icon_picker.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_slider_field.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_section_header.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/allocation_preview_widget.dart';

/// Page for creating or editing Focus screen definitions (DR-016).
///
/// Progressive single page with all sections visible:
/// - Basic info (name, icon, category)
/// - Persona selection (reusing AllocationPersona from settings)
/// - Task limit
/// - Advanced options (only for Custom persona)
/// - Source filter (narrow to specific projects)
/// - Live preview
class FocusScreenCreatorPage extends StatefulWidget {
  const FocusScreenCreatorPage({
    required this.screensRepository,
    required this.projectRepository,
    required this.allocationOrchestrator,
    required this.userId,
    this.existingScreen,
    super.key,
  });

  /// Repository for persisting screen definitions.
  final ScreenDefinitionsRepositoryContract screensRepository;

  /// Repository for loading projects.
  final ProjectRepositoryContract projectRepository;

  /// Allocation orchestrator for preview.
  final AllocationOrchestrator allocationOrchestrator;

  /// The user ID for the screen owner.
  final String userId;

  /// If provided, edits this existing screen instead of creating a new one.
  final ScreenDefinition? existingScreen;

  /// Whether we're editing an existing screen.
  bool get isEditing => existingScreen != null;

  @override
  State<FocusScreenCreatorPage> createState() => _FocusScreenCreatorPageState();
}

class _FocusScreenCreatorPageState extends State<FocusScreenCreatorPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  List<Project> _availableProjects = [];
  bool _isLoadingProjects = true;

  // Track persona for showing/hiding advanced options
  AllocationPersona _currentPersona = AllocationPersona.realist;

  // Strategy settings for Custom persona
  StrategySettings _strategySettings = const StrategySettings();

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _initializePersona();
  }

  void _initializePersona() {
    if (widget.existingScreen case final DataDrivenScreenDefinition screen) {
      if (screen.sections.isNotEmpty &&
          screen.sections.first is AllocationSection) {
        // For now, default to realist since we don't store persona directly
        // TODO: Store persona in screen definition
        _currentPersona = AllocationPersona.realist;
      }
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await widget.projectRepository.watchAll().first;
      if (mounted) {
        setState(() {
          _availableProjects = projects;
          _isLoadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProjects = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Focus Screen' : 'Create Focus Screen',
        ),
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
            FormSectionHeader(
              icon: Icons.info_outline,
              title: context.l10n.basicInfoSection,
            ),
            const SizedBox(height: 12),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),

            // ===== Persona Selection Section =====
            FormSectionHeader(
              icon: Icons.person_outline,
              title: context.l10n.personaSectionTitle,
              subtitle: context.l10n.personaSectionSubtitle,
            ),
            const SizedBox(height: 12),
            _buildPersonaSection(),
            const SizedBox(height: 24),

            // ===== Maximum Tasks =====
            FormSectionHeader(
              icon: Icons.format_list_numbered,
              title: context.l10n.taskLimitSection,
            ),
            const SizedBox(height: 12),
            _buildTaskLimitSection(),
            const SizedBox(height: 24),

            // ===== Advanced Options (only for Custom persona) =====
            if (_currentPersona == AllocationPersona.custom) ...[
              FormSectionHeader(
                icon: Icons.tune,
                title: context.l10n.advancedSettingsSection,
              ),
              const SizedBox(height: 12),
              _buildAdvancedSection(),
              const SizedBox(height: 24),
            ],

            // ===== Source Filter Section =====
            FormSectionHeader(
              icon: Icons.filter_list,
              title: context.l10n.sourceFilterSection,
              subtitle: context.l10n.sourceFilterSubtitle,
            ),
            const SizedBox(height: 12),
            _buildSourceFilterSection(),
            const SizedBox(height: 24),

            // ===== Preview Section =====
            AllocationPreviewWidget(
              allocationOrchestrator: widget.allocationOrchestrator,
              persona: _currentPersona,
              maxTasks:
                  ((_formKey.currentState?.fields['maxTasks']?.value
                              as double?) ??
                          10.0)
                      .round(),
            ),
            const SizedBox(height: 24),

            // ===== Save Button =====
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveScreen,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isSaving ? context.l10n.saving : context.l10n.saveFocusScreen,
              ),
            ),
            const SizedBox(height: 88), // Space for system UI
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        // Screen name
        FormBuilderTextField(
          name: 'name',
          decoration: const InputDecoration(
            labelText: 'Screen Name',
            hintText: 'e.g., "Daily Focus"',
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
      ],
    );
  }

  Widget _buildPersonaSection() {
    return Column(
      children: AllocationPersona.values.map((persona) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PersonaSelectionCard(
            persona: persona,
            isSelected: _currentPersona == persona,
            isRecommended: persona == AllocationPersona.realist,
            onTap: () => _onPersonaSelected(persona),
          ),
        );
      }).toList(),
    );
  }

  void _onPersonaSelected(AllocationPersona persona) {
    if (persona == _currentPersona) return;

    setState(() {
      _currentPersona = persona;
      // Apply preset strategy settings for the selected persona
      _strategySettings = StrategySettings.forPersona(persona);
    });
  }

  Widget _buildTaskLimitSection() {
    final l10n = context.l10n;
    return FormBuilderSliderField(
      name: 'maxTasks',
      min: 1,
      max: 25,
      initialValue: 10,
      divisions: 24,
      label: l10n.maxTasksLabel,
      formatValue: (v) => v.round().toString(),
    );
  }

  Widget _buildAdvancedSection() {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Urgency threshold
            FormBuilderSliderField(
              name: 'urgencyThresholdDays',
              min: 1,
              max: 14,
              initialValue: _strategySettings.taskUrgencyThresholdDays
                  .toDouble(),
              divisions: 13,
              label: l10n.taskUrgencyDays,
              formatValue: (v) => l10n.daysFormat(v.round()),
            ),
            const SizedBox(height: 16),

            // Urgent task behavior
            FormBuilderDropdown<UrgentTaskBehavior>(
              name: 'urgentTaskBehavior',
              initialValue: _strategySettings.urgentTaskBehavior,
              decoration: InputDecoration(
                labelText: l10n.urgentTaskBehaviorLabel,
                border: const OutlineInputBorder(),
              ),
              items: UrgentTaskBehavior.values.map((b) {
                return DropdownMenuItem(
                  value: b,
                  child: Text(_urgentBehaviorLabel(l10n, b)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Show excluded section
            FormBuilderSwitchTile(
              name: 'showExcludedSection',
              title: l10n.showExcludedSection,
              subtitle: l10n.showExcludedSectionSubtitle,
              initialValue: false,
            ),
          ],
        ),
      ),
    );
  }

  String _urgentBehaviorLabel(AppLocalizations l10n, UrgentTaskBehavior b) {
    return switch (b) {
      UrgentTaskBehavior.ignore => l10n.urgentBehaviorIgnore,
      UrgentTaskBehavior.warnOnly => l10n.urgentBehaviorWarnOnly,
      UrgentTaskBehavior.includeAll => l10n.urgentBehaviorIncludeAll,
    };
  }

  Widget _buildSourceFilterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source type radio
            FormBuilderRadioGroup<String>(
              name: 'sourceType',
              initialValue: 'all',
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              options: const [
                FormBuilderFieldOption(
                  value: 'all',
                  child: Text('All tasks'),
                ),
                FormBuilderFieldOption(
                  value: 'projects',
                  child: Text('Specific projects'),
                ),
              ],
              onChanged: (value) => setState(() {}),
            ),

            // Project selector (when 'projects' selected)
            Builder(
              builder: (context) {
                final sourceType =
                    _formKey.currentState?.fields['sourceType']?.value;
                if (sourceType != 'projects') return const SizedBox.shrink();

                if (_isLoadingProjects) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FormBuilderFilterChips<String>(
                    name: 'selectedProjects',
                    decoration: const InputDecoration(
                      labelText: 'Select Projects',
                      border: OutlineInputBorder(),
                    ),
                    options: _availableProjects.map((p) {
                      return FormBuilderChipOption(
                        value: p.id,
                        child: Text(p.name),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Include inbox toggle
            FormBuilderSwitchTile(
              name: 'includeInbox',
              title: 'Include inbox tasks',
              subtitle: 'Tasks without a project',
              initialValue: true,
            ),
            const SizedBox(height: 8),

            // Exclude future starts
            FormBuilderSwitchTile(
              name: 'excludeFutureStarts',
              title: 'Exclude future starts',
              subtitle: 'Hide tasks with start date in future',
              initialValue: true,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getInitialValues() {
    if (widget.existingScreen case final DataDrivenScreenDefinition screen) {
      // Extract values from existing screen
      int maxTasks = 10;
      bool showExcludedSection = false;

      if (screen.sections.isNotEmpty &&
          screen.sections.first is AllocationSection) {
        final section = screen.sections.first as AllocationSection;
        maxTasks = section.maxTasks ?? 10;
        showExcludedSection = section.showExcludedSection;
      }

      return {
        'name': screen.name,
        'iconName': screen.iconName,
        'category': screen.category,
        'maxTasks': maxTasks.toDouble(),
        'urgencyThresholdDays': _strategySettings.taskUrgencyThresholdDays
            .toDouble(),
        'urgentTaskBehavior': _strategySettings.urgentTaskBehavior,
        'showExcludedSection': showExcludedSection,
        'sourceType': 'all',
        'selectedProjects': <String>[],
        'includeInbox': true,
        'excludeFutureStarts': true,
      };
    }

    // Default values for new screen
    return {
      'name': '',
      'iconName': 'my_day',
      'category': ScreenCategory.workspace,
      'maxTasks': 10.0,
      'urgencyThresholdDays': _strategySettings.taskUrgencyThresholdDays
          .toDouble(),
      'urgentTaskBehavior': _strategySettings.urgentTaskBehavior,
      'showExcludedSection': false,
      'sourceType': 'all',
      'selectedProjects': <String>[],
      'includeInbox': true,
      'excludeFutureStarts': true,
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

      // Build source filter if specific projects selected
      TaskQuery? sourceFilter;
      final sourceType = values['sourceType'] as String;
      if (sourceType == 'projects') {
        final selectedProjects =
            (values['selectedProjects'] as List<String>?) ?? [];
        if (selectedProjects.isNotEmpty) {
          sourceFilter = TaskQuery(
            filter: QueryFilter<TaskPredicate>(
              shared: [
                TaskProjectPredicate(
                  operator: ProjectOperator.matchesAny,
                  projectIds: selectedProjects,
                ),
              ],
            ),
          );
        }
      }

      // Build the allocation section
      final maxTasks = (values['maxTasks'] as double).round();
      final showExcludedSection =
          values['showExcludedSection'] as bool? ?? false;
      final warnWhenUrgentExcluded =
          values['warnWhenUrgentExcluded'] as bool? ?? true;

      final section = Section.allocation(
        sourceFilter: sourceFilter,
        maxTasks: maxTasks,
        displayMode: AllocationDisplayMode.pinnedFirst,
        showExcludedWarnings: warnWhenUrgentExcluded,
        showExcludedSection: showExcludedSection,
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

        // Validate screenKey uniqueness
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
          id: '', // Repository generates v5 ID
          screenKey: screenKey,
          name: values['name'] as String,
          screenType: ScreenType.focus,
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
      talker.handle(e, st, '[FocusScreenCreatorPage] Error saving screen');
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
        title: const Text('Delete Focus Screen'),
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
        talker.handle(e, st, '[FocusScreenCreatorPage] Error deleting screen');
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

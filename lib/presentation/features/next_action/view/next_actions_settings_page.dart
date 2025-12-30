import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/priority_bucket_builder.dart';

/// Next actions settings page.
///
/// Reads and writes settings directly through the repository, ensuring
/// proper UDF (UI â†’ Repository) and maintaining consistency.
class NextActionsSettingsPage extends StatefulWidget {
  const NextActionsSettingsPage({super.key});

  @override
  State<NextActionsSettingsPage> createState() =>
      _NextActionsSettingsPageState();
}

class _NextActionsSettingsPageState extends State<NextActionsSettingsPage> {
  final SettingsRepositoryContract _settingsRepository =
      getIt<SettingsRepositoryContract>();
  late NextActionsSettings _settings;
  final _formKey = GlobalKey<FormState>();
  final _tasksPerProjectController = TextEditingController();
  late bool _includeInbox;
  late bool _excludeFutureStartDates;
  late List<TaskPriorityBucketRule> _buckets;

  // Track initial state for change detection
  late String _initialTasksPerProject;
  late bool _initialIncludeInbox;
  late bool _initialExcludeFutureStartDates;
  late List<TaskPriorityBucketRule> _initialBuckets;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    try {
      _settings = await _settingsRepository.loadNextActionsSettings();
      _tasksPerProjectController.text = _settings.tasksPerProject.toString();
      _includeInbox = _settings.includeInboxTasks;
      _excludeFutureStartDates = _settings.excludeFutureStartDates;
      _buckets = List.from(_settings.effectiveBucketRules);

      // Store initial state
      _initialTasksPerProject = _tasksPerProjectController.text;
      _initialIncludeInbox = _includeInbox;
      _initialExcludeFutureStartDates = _excludeFutureStartDates;
      _initialBuckets = List.from(_buckets);

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tasksPerProjectController.dispose();
    super.dispose();
  }

  List<TaskPriorityBucketRule> _createDefaultBuckets() {
    return NextActionsSettings.defaultBucketRules;
  }

  void _restoreDefaults() {
    setState(() {
      _tasksPerProjectController.text = '2';
      _includeInbox = true;
      _excludeFutureStartDates = true;
      _buckets = _createDefaultBuckets();
    });
  }

  bool _hasUnsavedChanges() {
    if (_tasksPerProjectController.text != _initialTasksPerProject) {
      return true;
    }
    if (_includeInbox != _initialIncludeInbox) {
      return true;
    }
    if (_excludeFutureStartDates != _initialExcludeFutureStartDates) {
      return true;
    }
    if (_buckets.length != _initialBuckets.length) {
      return true;
    }
    // Simple check - could be enhanced with deep equality if needed
    for (var i = 0; i < _buckets.length; i++) {
      if (_buckets[i] != _initialBuckets[i]) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save them before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              Navigator.of(context).pop(); // Discard and close
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              _save(); // Save and close
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleBack() async {
    if (_hasUnsavedChanges()) {
      final discard = await _confirmDiscard();
      if (!mounted) return;
      if (discard) {
        Navigator.of(context).pop();
      }
    } else {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tasksPerProject =
        int.tryParse(_tasksPerProjectController.text.trim()) ??
        _settings.tasksPerProject;

    // Normalize bucket priorities
    final normalizedBuckets = List.generate(
      _buckets.length,
      (index) => _buckets[index].copyWith(priority: index + 1),
    );

    final updatedSettings = NextActionsSettings(
      tasksPerProject: tasksPerProject,
      includeInboxTasks: _includeInbox,
      excludeFutureStartDates: _excludeFutureStartDates,
      bucketRules: normalizedBuckets,
      sortPreferences: _settings.sortPreferences,
    );

    try {
      // Save directly through adapter (optimistic update in repository)
      await _settingsRepository.saveNextActionsSettings(updatedSettings);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Next Actions Settings'),
          actions: [
            TextButton(
              onPressed: () {
                unawaited(_save());
              },
              child: const Text('Save'),
            ),
          ],
        ),
        body: FutureBuilder<({List<Label> labels, List<Project> projects})>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data;
            final labels = data?.labels ?? <Label>[];
            final projects = data?.projects ?? <Project>[];

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic settings
                    _BasicSettings(
                      tasksPerProjectController: _tasksPerProjectController,
                      includeInbox: _includeInbox,
                      excludeFutureStartDates: _excludeFutureStartDates,
                      onIncludeInboxChanged: (value) {
                        setState(() => _includeInbox = value);
                      },
                      onExcludeFutureStartDatesChanged: (value) {
                        setState(() => _excludeFutureStartDates = value);
                      },
                      onRestoreDefaults: _restoreDefaults,
                    ),

                    const SizedBox(height: 24),

                    // Priority buckets
                    PriorityBucketBuilder(
                      buckets: _buckets,
                      excludeFutureStartDates: _excludeFutureStartDates,
                      onChanged: (buckets) {
                        setState(() => _buckets = buckets);
                      },
                      availableLabels: labels,
                      availableProjects: projects,
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async => _handleBack(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _save,
                          child: const Text('Save Settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<({List<Label> labels, List<Project> projects})> _loadData() async {
    final labelRepo = getIt<LabelRepositoryContract>();
    final projectRepo = getIt<ProjectRepositoryContract>();

    final results = await Future.wait([
      labelRepo.getAll(),
      projectRepo.getAll(),
    ]);

    return (
      labels: results[0] as List<Label>,
      projects: results[1] as List<Project>,
    );
  }
}

class _BasicSettings extends StatelessWidget {
  const _BasicSettings({
    required this.tasksPerProjectController,
    required this.includeInbox,
    required this.excludeFutureStartDates,
    required this.onIncludeInboxChanged,
    required this.onExcludeFutureStartDatesChanged,
    required this.onRestoreDefaults,
  });

  final TextEditingController tasksPerProjectController;
  final bool includeInbox;
  final bool excludeFutureStartDates;
  final ValueChanged<bool> onIncludeInboxChanged;
  final ValueChanged<bool> onExcludeFutureStartDatesChanged;
  final VoidCallback onRestoreDefaults;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'General Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onRestoreDefaults,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Restore Defaults'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: tasksPerProjectController,
              decoration: const InputDecoration(
                labelText: 'Tasks per project',
                helperText: 'Maximum number of tasks shown per project',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a number';
                }
                final number = int.tryParse(value.trim());
                if (number == null || number < 1) {
                  return 'Please enter a number greater than 0';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Include inbox tasks'),
              subtitle: const Text(
                'Show tasks without a project in next actions',
              ),
              value: includeInbox,
              onChanged: onIncludeInboxChanged,
            ),

            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Exclude tasks with future start date'),
              subtitle: const Text(
                'Hide tasks that have a start date in the future',
              ),
              value: excludeFutureStartDates,
              onChanged: onExcludeFutureStartDatesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

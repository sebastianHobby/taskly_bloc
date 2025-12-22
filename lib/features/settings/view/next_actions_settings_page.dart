import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/settings/settings.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';
import 'package:taskly_bloc/features/tasks/widgets/priority_bucket_builder.dart';

/// Next actions settings page using the unified rule system.
class NextActionsSettingsPage extends StatefulWidget {
  const NextActionsSettingsPage({super.key});

  @override
  State<NextActionsSettingsPage> createState() =>
      _NextActionsSettingsPageState();
}

class _NextActionsSettingsPageState extends State<NextActionsSettingsPage> {
  late NextActionsSettings _settings;
  final _formKey = GlobalKey<FormState>();
  final _tasksPerProjectController = TextEditingController();
  late bool _includeInbox;
  late List<TaskPriorityBucketRule> _buckets;

  @override
  void initState() {
    super.initState();
    _settings =
        context.read<SettingsBloc>().state.settings?.nextActions ??
        const NextActionsSettings();
    _tasksPerProjectController.text = _settings.tasksPerProject.toString();
    _includeInbox = _settings.includeInboxTasks;
    _buckets = _settings.bucketRules.isEmpty
        ? _createDefaultBuckets()
        : List.from(_settings.bucketRules);
  }

  @override
  void dispose() {
    _tasksPerProjectController.dispose();
    super.dispose();
  }

  List<TaskPriorityBucketRule> _createDefaultBuckets() {
    return [
      TaskPriorityBucketRule(
        priority: 1,
        name: 'Deadline Soon',
        ruleSets: [
          TaskRuleSet(
            operator: RuleSetOperator.and,
            rules: [
              const DateRule(
                field: DateRuleField.deadlineDate,
                operator: DateRuleOperator.relative,
                relativeComparison: RelativeComparison.before,
                relativeDays: 7,
              ),
            ],
          ),
        ],
      ),
    ];
  }

  void _save() {
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
      bucketRules: normalizedBuckets,
      sortPreferences: _settings.sortPreferences,
    );

    context.read<SettingsBloc>().add(
      SettingsUpdateNextActions(settings: updatedSettings),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next Actions Settings'),
        actions: [
          TextButton(
            onPressed: _save,
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
                    onIncludeInboxChanged: (value) {
                      setState(() => _includeInbox = value);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Priority buckets
                  PriorityBucketBuilder(
                    buckets: _buckets,
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
                        onPressed: () => Navigator.of(context).pop(),
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
    required this.onIncludeInboxChanged,
  });

  final TextEditingController tasksPerProjectController;
  final bool includeInbox;
  final ValueChanged<bool> onIncludeInboxChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleMedium,
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
          ],
        ),
      ),
    );
  }
}

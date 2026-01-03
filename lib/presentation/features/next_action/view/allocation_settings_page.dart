import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/presentation/features/next_action/widgets/persona_selection_card.dart';

/// Settings page for configuring task allocation strategy and value rankings.
class AllocationSettingsPage extends StatefulWidget {
  const AllocationSettingsPage({
    required this.settingsRepository,
    required this.labelRepository,
    super.key,
  });

  final SettingsRepositoryContract settingsRepository;
  final LabelRepositoryContract labelRepository;

  @override
  State<AllocationSettingsPage> createState() => _AllocationSettingsPageState();
}

class _AllocationSettingsPageState extends State<AllocationSettingsPage> {
  SettingsRepositoryContract get _settingsRepo => widget.settingsRepository;
  LabelRepositoryContract get _labelRepo => widget.labelRepository;

  // Preserved for debugging/future enhancements
  // ignore: unused_field
  AllocationConfig? _allocationConfig;
  // ignore: unused_field
  ValueRanking? _valueRanking;
  // ignore: unused_field
  List<Label> _valueLabels = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  // Form state - initialized with defaults to prevent LateInitializationError
  AllocationPersona _persona = AllocationPersona.realist;
  int _dailyTaskLimit = 10;

  // Strategy settings
  UrgentTaskBehavior _urgentTaskBehavior = UrgentTaskBehavior.warnOnly;
  int _taskUrgencyThresholdDays = 3;
  int _projectUrgencyThresholdDays = 7;
  double _urgencyBoostMultiplier = 1.5;
  bool _enableNeglectWeighting = false;
  int _neglectLookbackDays = 7;
  double _neglectInfluence = 0.7;

  // Display settings
  bool _showOrphanTaskCount = true;
  bool _showProjectNextTask = true;

  // Value rankings
  List<_RankableValue> _rankedValues = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _settingsRepo.load(SettingsKey.allocation);
      final ranking = await _settingsRepo.load(SettingsKey.valueRanking);
      final labels = await _labelRepo.getAllByType(LabelType.value);

      _allocationConfig = settings;
      _valueRanking = ranking;
      _valueLabels = labels;

      // Initialize form state from settings
      _persona = settings.persona;
      _dailyTaskLimit = settings.dailyLimit;

      // Strategy settings
      _urgentTaskBehavior = settings.strategySettings.urgentTaskBehavior;
      _taskUrgencyThresholdDays =
          settings.strategySettings.taskUrgencyThresholdDays;
      _projectUrgencyThresholdDays =
          settings.strategySettings.projectUrgencyThresholdDays;
      _urgencyBoostMultiplier =
          settings.strategySettings.urgencyBoostMultiplier;
      _enableNeglectWeighting =
          settings.strategySettings.enableNeglectWeighting;
      _neglectLookbackDays = settings.strategySettings.neglectLookbackDays;
      _neglectInfluence = settings.strategySettings.neglectInfluence;

      // Display settings
      _showOrphanTaskCount = settings.displaySettings.showOrphanTaskCount;
      _showProjectNextTask = settings.displaySettings.showProjectNextTask;

      // Build ranked values list
      _rankedValues = _buildRankedValues(labels, ranking);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<_RankableValue> _buildRankedValues(
    List<Label> labels,
    ValueRanking? ranking,
  ) {
    final rankedItems = ranking?.items ?? [];
    final rankedMap = {for (final item in rankedItems) item.labelId: item};

    final ranked = <_RankableValue>[];
    final unranked = <_RankableValue>[];

    for (final label in labels) {
      final item = rankedMap[label.id];
      if (item != null) {
        ranked.add(
          _RankableValue(label: label, weight: item.weight, isRanked: true),
        );
      } else {
        unranked.add(
          _RankableValue(label: label, weight: 5, isRanked: false),
        );
      }
    }

    ranked.sort((a, b) => b.weight.compareTo(a.weight));
    return [...ranked, ...unranked];
  }

  void _onPersonaSelected(AllocationPersona persona) {
    if (persona == _persona) return;

    setState(() {
      _persona = persona;

      // Apply preset strategy settings for the selected persona
      final preset = StrategySettings.forPersona(persona);
      _urgentTaskBehavior = preset.urgentTaskBehavior;
      _taskUrgencyThresholdDays = preset.taskUrgencyThresholdDays;
      _projectUrgencyThresholdDays = preset.projectUrgencyThresholdDays;
      _urgencyBoostMultiplier = preset.urgencyBoostMultiplier;
      _enableNeglectWeighting = preset.enableNeglectWeighting;
      _neglectLookbackDays = preset.neglectLookbackDays;
      _neglectInfluence = preset.neglectInfluence;

      _hasChanges = true;
    });
  }

  /// Check if current strategy settings differ from the current persona's
  /// preset. If so, auto-switch to Custom and show feedback.
  void _checkAutoSwitchToCustom() {
    if (_persona == AllocationPersona.custom) return;

    final preset = StrategySettings.forPersona(_persona);
    final current = StrategySettings(
      urgentTaskBehavior: _urgentTaskBehavior,
      taskUrgencyThresholdDays: _taskUrgencyThresholdDays,
      projectUrgencyThresholdDays: _projectUrgencyThresholdDays,
      urgencyBoostMultiplier: _urgencyBoostMultiplier,
      enableNeglectWeighting: _enableNeglectWeighting,
      neglectLookbackDays: _neglectLookbackDays,
      neglectInfluence: _neglectInfluence,
    );

    if (current != preset) {
      setState(() => _persona = AllocationPersona.custom);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.switchedToCustomMode),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onValueReordered(int oldIndex, int newIndex) {
    setState(() {
      var adjustedNewIndex = newIndex;
      if (oldIndex < newIndex) adjustedNewIndex -= 1;
      final item = _rankedValues.removeAt(oldIndex);
      _rankedValues.insert(adjustedNewIndex, item);

      for (var i = 0; i < _rankedValues.length; i++) {
        _rankedValues[i] = _rankedValues[i].copyWith(
          weight: 10 - i.clamp(0, 9),
          isRanked: true,
        );
      }
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    try {
      await _settingsRepo.save(
        SettingsKey.allocation,
        AllocationConfig(
          persona: _persona,
          dailyLimit: _dailyTaskLimit,
          strategySettings: StrategySettings(
            urgentTaskBehavior: _urgentTaskBehavior,
            taskUrgencyThresholdDays: _taskUrgencyThresholdDays,
            projectUrgencyThresholdDays: _projectUrgencyThresholdDays,
            urgencyBoostMultiplier: _urgencyBoostMultiplier,
            enableNeglectWeighting: _enableNeglectWeighting,
            neglectLookbackDays: _neglectLookbackDays,
            neglectInfluence: _neglectInfluence,
          ),
          displaySettings: DisplaySettings(
            showOrphanTaskCount: _showOrphanTaskCount,
            showProjectNextTask: _showProjectNextTask,
          ),
        ),
      );

      final rankedItems = _rankedValues
          .where((v) => v.isRanked)
          .map(
            (v) => ValueRankItem(
              labelId: v.label.id,
              weight: v.weight,
              sortOrder: _rankedValues.indexOf(v),
            ),
          )
          .toList();

      await _settingsRepo.save(
        SettingsKey.valueRanking,
        ValueRanking(items: rankedItems),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allocationSettingsTitle),
        actions: [
          TextButton(
            onPressed: _hasChanges ? _save : null,
            child: Text(l10n.saveLabel),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section 1: Persona Selection
                _buildPersonaSection(theme, l10n),
                const SizedBox(height: 24),

                // Section 2: Urgency Thresholds
                _buildThresholdsSection(theme, l10n),
                const SizedBox(height: 24),

                // Section 3: Display Options
                _buildDisplayOptionsSection(theme, l10n),
                const SizedBox(height: 24),

                // Section 4: Advanced Settings (only for Custom)
                if (_persona == AllocationPersona.custom) ...[
                  _buildAdvancedSettingsSection(theme, l10n),
                  const SizedBox(height: 24),
                ],

                // Section 5: Value Rankings
                _buildValueRankingsSection(theme, l10n),
              ],
            ),
    );
  }

  Widget _buildPersonaSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.personaSectionTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...AllocationPersona.values.map((persona) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PersonaSelectionCard(
              persona: persona,
              isSelected: _persona == persona,
              isRecommended: persona == AllocationPersona.realist,
              onTap: () => _onPersonaSelected(persona),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildThresholdsSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.urgencyThresholdsSection,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.taskUrgencyDays),
              trailing: SizedBox(
                width: 80,
                child: TextFormField(
                  key: ValueKey('task_threshold_$_taskUrgencyThresholdDays'),
                  initialValue: _taskUrgencyThresholdDays.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed >= 0) {
                      setState(() {
                        _taskUrgencyThresholdDays = parsed;
                        _hasChanges = true;
                      });
                      _checkAutoSwitchToCustom();
                    }
                  },
                ),
              ),
            ),
            ListTile(
              title: Text(l10n.projectUrgencyDays),
              trailing: SizedBox(
                width: 80,
                child: TextFormField(
                  key: ValueKey(
                    'project_threshold_$_projectUrgencyThresholdDays',
                  ),
                  initialValue: _projectUrgencyThresholdDays.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed >= 0) {
                      setState(() {
                        _projectUrgencyThresholdDays = parsed;
                        _hasChanges = true;
                      });
                      _checkAutoSwitchToCustom();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayOptionsSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.displayOptionsSection,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.showUnassignedTaskCount),
              value: _showOrphanTaskCount,
              onChanged: (v) => setState(() {
                _showOrphanTaskCount = v;
                _hasChanges = true;
              }),
            ),
            SwitchListTile(
              title: Text(l10n.showProjectNextTask),
              value: _showProjectNextTask,
              onChanged: (v) => setState(() {
                _showProjectNextTask = v;
                _hasChanges = true;
              }),
            ),
            ListTile(
              title: Text(l10n.dailyTaskLimit),
              trailing: SizedBox(
                width: 80,
                child: TextFormField(
                  key: ValueKey('limit_$_dailyTaskLimit'),
                  initialValue: _dailyTaskLimit.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        _dailyTaskLimit = parsed;
                        _hasChanges = true;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.advancedSettingsSection,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Urgent task handling
            Text(
              l10n.urgentTaskHandling,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...UrgentTaskBehavior.values.map((behavior) {
              return RadioListTile<UrgentTaskBehavior>(
                title: Text(_urgentBehaviorName(l10n, behavior)),
                subtitle: Text(_urgentBehaviorDescription(l10n, behavior)),
                value: behavior,
                groupValue: _urgentTaskBehavior,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _urgentTaskBehavior = v;
                      _hasChanges = true;
                    });
                  }
                },
              );
            }),

            const Divider(height: 32),

            // Urgency boost multiplier
            Text(
              '${l10n.valueAlignedUrgencyBoost}: '
              '${_urgencyBoostMultiplier.toStringAsFixed(1)}x',
              style: theme.textTheme.titleSmall,
            ),
            Slider(
              value: _urgencyBoostMultiplier,
              min: 1,
              max: 3,
              divisions: 20,
              label: '${_urgencyBoostMultiplier.toStringAsFixed(1)}x',
              onChanged: (v) => setState(() {
                _urgencyBoostMultiplier = v;
                _hasChanges = true;
              }),
            ),

            const Divider(height: 32),

            // Reflector settings
            SwitchListTile(
              title: Text(l10n.enableNeglectWeighting),
              value: _enableNeglectWeighting,
              onChanged: (v) => setState(() {
                _enableNeglectWeighting = v;
                _hasChanges = true;
              }),
            ),

            if (_enableNeglectWeighting) ...[
              ListTile(
                title: Text(l10n.reflectorLookbackDays),
                trailing: SizedBox(
                  width: 80,
                  child: TextFormField(
                    key: ValueKey('lookback_$_neglectLookbackDays'),
                    initialValue: _neglectLookbackDays.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          _neglectLookbackDays = parsed;
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                ),
              ),
              ListTile(
                title: Text(l10n.neglectInfluence),
                subtitle: Slider(
                  value: _neglectInfluence,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: _neglectInfluence.toStringAsFixed(1),
                  onChanged: (v) => setState(() {
                    _neglectInfluence = v;
                    _hasChanges = true;
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValueRankingsSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.valueRankingsTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.valueRankingsDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_rankedValues.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.noValuesForRanking,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rankedValues.length,
                onReorder: _onValueReordered,
                itemBuilder: (context, index) {
                  final value = _rankedValues[index];
                  return _ValueRankTile(
                    key: ValueKey(value.label.id),
                    value: value,
                    index: index,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _urgentBehaviorName(AppLocalizations l10n, UrgentTaskBehavior b) {
    return switch (b) {
      UrgentTaskBehavior.ignore => l10n.urgentTaskIgnore,
      UrgentTaskBehavior.warnOnly => l10n.urgentTaskWarnOnly,
      UrgentTaskBehavior.includeAll => l10n.urgentTaskIncludeAll,
    };
  }

  String _urgentBehaviorDescription(
    AppLocalizations l10n,
    UrgentTaskBehavior b,
  ) {
    return switch (b) {
      UrgentTaskBehavior.ignore => l10n.urgentTaskIgnoreDescription,
      UrgentTaskBehavior.warnOnly => l10n.urgentTaskWarnOnlyDescription,
      UrgentTaskBehavior.includeAll => l10n.urgentTaskIncludeAllDescription,
    };
  }
}

class _RankableValue {
  const _RankableValue({
    required this.label,
    required this.weight,
    required this.isRanked,
  });

  final Label label;
  final int weight;
  final bool isRanked;

  _RankableValue copyWith({Label? label, int? weight, bool? isRanked}) {
    return _RankableValue(
      label: label ?? this.label,
      weight: weight ?? this.weight,
      isRanked: isRanked ?? this.isRanked,
    );
  }
}

class _ValueRankTile extends StatelessWidget {
  const _ValueRankTile({
    required super.key,
    required this.value,
    required this.index,
  });

  final _RankableValue value;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final label = value.label;

    return Material(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(label.name),
        subtitle: value.isRanked
            ? Text('${l10n.weightLabel}: ${value.weight}')
            : Text(
                l10n.notRankedDragToRank,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';

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

  // Preserved for future value ranking feature - nullable is intentional
  // ignore: unused_field
  AllocationConfig? _allocationConfig;
  // Preserved for future value ranking feature - nullable is intentional
  // ignore: unused_field
  ValueRanking? _valueRanking;
  // Preserved for future value ranking feature
  // ignore: unused_field
  List<Label> _valueLabels = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  // Form state - initialized with defaults to prevent LateInitializationError
  AllocationPersona _persona = AllocationPersona.realist;
  double _urgencyBoostMultiplier = 1.5;
  int _dailyTaskLimit = 10;
  int _taskUrgencyThresholdDays = 3;
  UrgentTaskBehavior _urgentTaskBehavior = UrgentTaskBehavior.warnOnly;
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
      _urgencyBoostMultiplier =
          settings.strategySettings.urgencyBoostMultiplier;
      _dailyTaskLimit = settings.dailyLimit;
      _taskUrgencyThresholdDays =
          settings.strategySettings.taskUrgencyThresholdDays;
      _urgentTaskBehavior = settings.strategySettings.urgentTaskBehavior;

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

    // Build list with ranked items first (in order), then unranked
    final ranked = <_RankableValue>[];
    final unranked = <_RankableValue>[];

    for (final label in labels) {
      final item = rankedMap[label.id];
      if (item != null) {
        ranked.add(
          _RankableValue(
            label: label,
            weight: item.weight,
            isRanked: true,
          ),
        );
      } else {
        unranked.add(
          _RankableValue(
            label: label,
            weight: 5, // Default weight
            isRanked: false,
          ),
        );
      }
    }

    // Sort ranked by weight descending
    ranked.sort((a, b) => b.weight.compareTo(a.weight));

    return [...ranked, ...unranked];
  }

  void _onPersonaChanged(AllocationPersona? value) {
    if (value != null && value != _persona) {
      setState(() {
        _persona = value;
        // Apply preset for the selected persona
        final preset = StrategySettings.forPersona(value);
        _urgentTaskBehavior = preset.urgentTaskBehavior;
        _urgencyBoostMultiplier = preset.urgencyBoostMultiplier;
        _hasChanges = true;
      });
    }
  }

  void _onValueReordered(int oldIndex, int newIndex) {
    setState(() {
      var adjustedNewIndex = newIndex;
      if (oldIndex < newIndex) adjustedNewIndex -= 1;
      final item = _rankedValues.removeAt(oldIndex);
      _rankedValues.insert(adjustedNewIndex, item);

      // Update weights based on position
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
      // Save allocation settings
      await _settingsRepo.save(
        SettingsKey.allocation,
        AllocationConfig(
          persona: _persona,
          dailyLimit: _dailyTaskLimit,
          strategySettings: StrategySettings(
            urgentTaskBehavior: _urgentTaskBehavior,
            urgencyBoostMultiplier: _urgencyBoostMultiplier,
            taskUrgencyThresholdDays: _taskUrgencyThresholdDays,
          ),
        ),
      );

      // Save value ranking
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

      if (mounted) {
        Navigator.of(context).pop();
      }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocation Settings'),
        actions: [
          TextButton(
            onPressed: _hasChanges ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Persona selection
                _PersonaCard(
                  persona: _persona,
                  onChanged: _onPersonaChanged,
                ),
                const SizedBox(height: 16),

                // Strategy-specific settings
                _StrategySettingsCard(
                  persona: _persona,
                  urgencyBoostMultiplier: _urgencyBoostMultiplier,
                  dailyTaskLimit: _dailyTaskLimit,
                  taskUrgencyThresholdDays: _taskUrgencyThresholdDays,
                  urgentTaskBehavior: _urgentTaskBehavior,
                  onUrgencyBoostChanged: (v) => setState(() {
                    _urgencyBoostMultiplier = v;
                    _persona = AllocationPersona.custom;
                    _hasChanges = true;
                  }),
                  onDailyLimitChanged: (v) => setState(() {
                    _dailyTaskLimit = v;
                    _hasChanges = true;
                  }),
                  onUrgencyThresholdChanged: (v) => setState(() {
                    _taskUrgencyThresholdDays = v;
                    _persona = AllocationPersona.custom;
                    _hasChanges = true;
                  }),
                  onUrgentTaskBehaviorChanged: (v) => setState(() {
                    _urgentTaskBehavior = v;
                    _persona = AllocationPersona.custom;
                    _hasChanges = true;
                  }),
                ),
                const SizedBox(height: 16),

                // Value rankings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Value Rankings',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Drag to reorder. Higher values get more focus tasks.',
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
                                'No values found. Create values in the Values screen.',
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
                ),
              ],
            ),
    );
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

  _RankableValue copyWith({
    Label? label,
    int? weight,
    bool? isRanked,
  }) {
    return _RankableValue(
      label: label ?? this.label,
      weight: weight ?? this.weight,
      isRanked: isRanked ?? this.isRanked,
    );
  }
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.persona,
    required this.onChanged,
  });

  final AllocationPersona persona;
  final ValueChanged<AllocationPersona?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Allocation Persona',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AllocationPersona.values.map((type) {
              final isRecommended = type == AllocationPersona.realist;

              return RadioListTile<AllocationPersona>(
                title: Row(
                  children: [
                    Text(_personaName(type)),
                    if (isRecommended) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: const Text('Recommended'),
                        labelStyle: theme.textTheme.labelSmall,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  _personaDescription(type),
                  style: theme.textTheme.bodySmall,
                ),
                value: type,
                groupValue: persona,
                onChanged: onChanged,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _personaName(AllocationPersona type) {
    return switch (type) {
      AllocationPersona.idealist => 'Idealist',
      AllocationPersona.reflector => 'Reflector',
      AllocationPersona.realist => 'Realist',
      AllocationPersona.firefighter => 'Firefighter',
      AllocationPersona.custom => 'Custom',
    };
  }

  String _personaDescription(AllocationPersona type) {
    return switch (type) {
      AllocationPersona.idealist =>
        'Pure value alignment. Ignores urgency entirely.',
      AllocationPersona.reflector =>
        "Prioritizes values you've been neglecting.",
      AllocationPersona.realist => 'Balanced approach with urgency awareness.',
      AllocationPersona.firefighter =>
        'Urgency-first. All urgent tasks included.',
      AllocationPersona.custom => 'Configure all settings manually.',
    };
  }
}

class _StrategySettingsCard extends StatelessWidget {
  const _StrategySettingsCard({
    required this.persona,
    required this.urgencyBoostMultiplier,
    required this.dailyTaskLimit,
    required this.taskUrgencyThresholdDays,
    required this.urgentTaskBehavior,
    required this.onUrgencyBoostChanged,
    required this.onDailyLimitChanged,
    required this.onUrgencyThresholdChanged,
    required this.onUrgentTaskBehaviorChanged,
  });

  final AllocationPersona persona;
  final double urgencyBoostMultiplier;
  final int dailyTaskLimit;
  final int taskUrgencyThresholdDays;
  final UrgentTaskBehavior urgentTaskBehavior;
  final ValueChanged<double> onUrgencyBoostChanged;
  final ValueChanged<int> onDailyLimitChanged;
  final ValueChanged<int> onUrgencyThresholdChanged;
  final ValueChanged<UrgentTaskBehavior> onUrgentTaskBehaviorChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Persona-specific settings visibility
    final showUrgencySettings = persona != AllocationPersona.idealist;
    final isEditable = persona == AllocationPersona.custom;

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
                  'Strategy Settings',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Daily task limit (always visible)
            ListTile(
              title: const Text('Daily Focus Limit'),
              subtitle: const Text('Maximum tasks in your daily focus list'),
              trailing: SizedBox(
                width: 80,
                child: TextFormField(
                  key: ValueKey('limit_$dailyTaskLimit'),
                  initialValue: dailyTaskLimit.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      onDailyLimitChanged(parsed);
                    }
                  },
                ),
              ),
            ),

            // Urgency settings (hidden for Idealist)
            if (showUrgencySettings) ...[
              const Divider(height: 24),
              Text(
                'Urgency Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // Urgency threshold days
              ListTile(
                title: const Text('Urgency Threshold'),
                subtitle: const Text('Days before deadline to flag as urgent'),
                trailing: SizedBox(
                  width: 80,
                  child: TextFormField(
                    key: ValueKey('threshold_$taskUrgencyThresholdDays'),
                    initialValue: taskUrgencyThresholdDays.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    enabled: isEditable,
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed >= 0) {
                        onUrgencyThresholdChanged(parsed);
                      }
                    },
                  ),
                ),
              ),

              // Urgency boost multiplier slider
              const SizedBox(height: 8),
              Text(
                'Urgency Boost: ${urgencyBoostMultiplier.toStringAsFixed(1)}x',
                style: theme.textTheme.bodyMedium,
              ),
              Slider(
                value: urgencyBoostMultiplier,
                min: 1,
                max: 3,
                divisions: 20,
                label: '${urgencyBoostMultiplier.toStringAsFixed(1)}x',
                onChanged: isEditable ? onUrgencyBoostChanged : null,
              ),
              Text(
                'How much urgent tasks are boosted in scoring',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 16),

              // Urgent task behavior dropdown
              ListTile(
                title: const Text('Urgent Task Behavior'),
                subtitle: Text(_urgentBehaviorDescription(urgentTaskBehavior)),
                trailing: DropdownButton<UrgentTaskBehavior>(
                  value: urgentTaskBehavior,
                  onChanged: isEditable
                      ? (v) {
                          if (v != null) onUrgentTaskBehaviorChanged(v);
                        }
                      : null,
                  items: UrgentTaskBehavior.values.map((behavior) {
                    return DropdownMenuItem(
                      value: behavior,
                      child: Text(_urgentBehaviorName(behavior)),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Info about non-custom personas
            if (!isEditable) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select "Custom" persona to modify these settings.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _urgentBehaviorName(UrgentTaskBehavior behavior) {
    return switch (behavior) {
      UrgentTaskBehavior.warnOnly => 'Warn Only',
      UrgentTaskBehavior.includeAll => 'Always Include',
      UrgentTaskBehavior.ignore => 'Ignore',
    };
  }

  String _urgentBehaviorDescription(UrgentTaskBehavior behavior) {
    return switch (behavior) {
      UrgentTaskBehavior.warnOnly => 'Urgent tasks excluded but show warnings',
      UrgentTaskBehavior.includeAll => 'All urgent tasks are included',
      UrgentTaskBehavior.ignore => 'Urgency has no effect, no warnings',
    };
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
            ? Text('Weight: ${value.weight}')
            : Text(
                'Not ranked - drag to rank',
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

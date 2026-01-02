import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/settings.dart';

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
  AllocationSettings? _allocationSettings;
  // Preserved for future value ranking feature - nullable is intentional
  // ignore: unused_field
  ValueRanking? _valueRanking;
  // Preserved for future value ranking feature
  // ignore: unused_field
  List<Label> _valueLabels = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  // Form state - initialized with defaults to prevent LateInitializationError
  AllocationStrategyType _strategyType = AllocationStrategyType.proportional;
  double _urgencyInfluence = 0.4;
  int _dailyTaskLimit = 10;
  int _urgencyThresholdDays = 3;
  bool _showExcludedWarning = true;
  List<_RankableValue> _rankedValues = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _settingsRepo.loadAllocationSettings();
      final ranking = await _settingsRepo.loadValueRanking();
      final labels = await _labelRepo.getAllByType(LabelType.value);

      _allocationSettings = settings;
      _valueRanking = ranking;
      _valueLabels = labels;

      // Initialize form state from settings
      _strategyType = settings.strategyType;
      _urgencyInfluence = settings.urgencyInfluence;
      _dailyTaskLimit = settings.dailyTaskLimit;
      _urgencyThresholdDays = 3; // Default - not stored in new settings
      _showExcludedWarning = settings.showExcludedUrgentWarning;

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

  void _onStrategyChanged(AllocationStrategyType? value) {
    if (value != null && value != _strategyType) {
      setState(() {
        _strategyType = value;
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
      await _settingsRepo.saveAllocationSettings(
        AllocationSettings(
          strategyType: _strategyType,
          urgencyInfluence: _urgencyInfluence,
          dailyTaskLimit: _dailyTaskLimit,
          showExcludedUrgentWarning: _showExcludedWarning,
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

      await _settingsRepo.saveValueRanking(
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
                // Strategy selection
                _StrategyCard(
                  strategyType: _strategyType,
                  onChanged: _onStrategyChanged,
                ),
                const SizedBox(height: 16),

                // Strategy-specific settings
                _StrategySettingsCard(
                  strategyType: _strategyType,
                  urgencyInfluence: _urgencyInfluence,
                  dailyTaskLimit: _dailyTaskLimit,
                  urgencyThresholdDays: _urgencyThresholdDays,
                  showExcludedWarning: _showExcludedWarning,
                  onUrgencyInfluenceChanged: (v) => setState(() {
                    _urgencyInfluence = v;
                    _hasChanges = true;
                  }),
                  onDailyLimitChanged: (v) => setState(() {
                    _dailyTaskLimit = v;
                    _hasChanges = true;
                  }),
                  onUrgencyThresholdChanged: (v) => setState(() {
                    _urgencyThresholdDays = v;
                    _hasChanges = true;
                  }),
                  onShowWarningChanged: (v) => setState(() {
                    _showExcludedWarning = v;
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

class _StrategyCard extends StatelessWidget {
  const _StrategyCard({
    required this.strategyType,
    required this.onChanged,
  });

  final AllocationStrategyType strategyType;
  final ValueChanged<AllocationStrategyType?> onChanged;

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
                  'Allocation Strategy',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AllocationStrategyType.values.map((type) {
              final isImplemented =
                  type == AllocationStrategyType.proportional ||
                  type == AllocationStrategyType.urgencyWeighted;

              return RadioListTile<AllocationStrategyType>(
                title: Text(_strategyName(type)),
                subtitle: Text(
                  _strategyDescription(type),
                  style: theme.textTheme.bodySmall,
                ),
                value: type,
                groupValue: strategyType,
                onChanged: isImplemented ? onChanged : null,
                secondary: !isImplemented
                    ? Chip(
                        label: const Text('Coming Soon'),
                        labelStyle: theme.textTheme.labelSmall,
                      )
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _strategyName(AllocationStrategyType type) {
    return switch (type) {
      AllocationStrategyType.proportional => 'Proportional',
      AllocationStrategyType.urgencyWeighted => 'Urgency Weighted',
      AllocationStrategyType.roundRobin => 'Round Robin',
      AllocationStrategyType.minimumViable => 'Minimum Viable',
      AllocationStrategyType.dynamic => 'Dynamic',
      AllocationStrategyType.topCategories => 'Top Categories',
    };
  }

  String _strategyDescription(AllocationStrategyType type) {
    return switch (type) {
      AllocationStrategyType.proportional =>
        'Allocate tasks proportionally based on value rankings',
      AllocationStrategyType.urgencyWeighted =>
        'Balance value rankings with task urgency',
      AllocationStrategyType.roundRobin => 'Cycle through values equally',
      AllocationStrategyType.minimumViable =>
        'Ensure minimum tasks per value before extras',
      AllocationStrategyType.dynamic => 'Adapt strategy based on workload',
      AllocationStrategyType.topCategories =>
        'Focus on top N ranked values only',
    };
  }
}

class _StrategySettingsCard extends StatelessWidget {
  const _StrategySettingsCard({
    required this.strategyType,
    required this.urgencyInfluence,
    required this.dailyTaskLimit,
    required this.urgencyThresholdDays,
    required this.showExcludedWarning,
    required this.onUrgencyInfluenceChanged,
    required this.onDailyLimitChanged,
    required this.onUrgencyThresholdChanged,
    required this.onShowWarningChanged,
  });

  final AllocationStrategyType strategyType;
  final double urgencyInfluence;
  final int dailyTaskLimit;
  final int urgencyThresholdDays;
  final bool showExcludedWarning;
  final ValueChanged<double> onUrgencyInfluenceChanged;
  final ValueChanged<int> onDailyLimitChanged;
  final ValueChanged<int> onUrgencyThresholdChanged;
  final ValueChanged<bool> onShowWarningChanged;

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
                Icon(Icons.settings, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Strategy Settings',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Daily task limit
            ListTile(
              title: const Text('Daily Focus Limit'),
              subtitle: Text('Maximum tasks in your daily focus list'),
              trailing: SizedBox(
                width: 80,
                child: TextFormField(
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

            // Urgency threshold
            ListTile(
              title: const Text('Urgency Threshold'),
              subtitle: Text('Days before deadline to flag as urgent'),
              trailing: SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: urgencyThresholdDays.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed >= 0) {
                      onUrgencyThresholdChanged(parsed);
                    }
                  },
                ),
              ),
            ),

            // Urgency influence (only for urgency weighted)
            if (strategyType == AllocationStrategyType.urgencyWeighted) ...[
              const SizedBox(height: 8),
              Text(
                'Urgency Influence: ${(urgencyInfluence * 100).round()}%',
                style: theme.textTheme.bodyMedium,
              ),
              Slider(
                value: urgencyInfluence,
                divisions: 10,
                label: '${(urgencyInfluence * 100).round()}%',
                onChanged: onUrgencyInfluenceChanged,
              ),
              Text(
                'How much urgency affects task selection vs value ranking',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const Divider(height: 32),

            // Warning toggle
            SwitchListTile(
              title: const Text('Show Excluded Task Warnings'),
              subtitle: const Text(
                'Alert when urgent tasks are excluded from focus',
              ),
              value: showExcludedWarning,
              onChanged: onShowWarningChanged,
            ),
          ],
        ),
      ),
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

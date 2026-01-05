import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/presentation/features/next_action/widgets/persona_selection_card.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/enhanced_value_card.dart';

/// Settings page for configuring task allocation strategy and value rankings.
class AllocationSettingsPage extends StatefulWidget {
  const AllocationSettingsPage({
    required this.settingsRepository,
    required this.valueRepository,
    super.key,
  });

  final SettingsRepositoryContract settingsRepository;
  final ValueRepositoryContract valueRepository;

  @override
  State<AllocationSettingsPage> createState() => _AllocationSettingsPageState();
}

class _AllocationSettingsPageState extends State<AllocationSettingsPage> {
  SettingsRepositoryContract get _settingsRepo => widget.settingsRepository;
  ValueRepositoryContract get _valueRepo => widget.valueRepository;

  // Preserved for debugging/future enhancements
  // ignore: unused_field
  AllocationConfig? _allocationConfig;
  // ignore: unused_field
  ValueRanking? _valueRanking;
  // ignore: unused_field
  List<Value> _values = [];
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
      developer.log('[AllocationSettingsPage] Loading settings...');
      final settings = await _settingsRepo.load(SettingsKey.allocation);
      developer.log(
        '[AllocationSettingsPage] Loaded allocation: '
        'dailyLimit=${settings.dailyLimit}, persona=${settings.persona}',
      );

      final ranking = await _settingsRepo.load(SettingsKey.valueRanking);
      developer.log(
        '[AllocationSettingsPage] Loaded valueRanking: '
        '${ranking.items.length} items\n'
        '  items=${ranking.items.map((i) => "${i.valueId.substring(0, 8)}:w${i.weight}").join(", ")}',
      );

      final values = await _valueRepo.getAll();
      developer.log(
        '[AllocationSettingsPage] Loaded ${values.length} values: '
        '${values.map((l) => "${l.name}(${l.id.substring(0, 8)})").join(", ")}',
      );

      _allocationConfig = settings;
      _valueRanking = ranking;
      _values = values;

      // Initialize form state from settings
      _persona = settings.persona;
      _dailyTaskLimit = settings.dailyLimit;

      // Strategy settings
      _urgentTaskBehavior = settings.urgentTaskBehavior;
      _taskUrgencyThresholdDays = settings.taskUrgencyThresholdDays;
      _projectUrgencyThresholdDays = settings.projectUrgencyThresholdDays;
      _urgencyBoostMultiplier = settings.urgencyBoostMultiplier;
      _enableNeglectWeighting = settings.enableNeglectWeighting;
      _neglectLookbackDays = settings.neglectLookbackDays;
      _neglectInfluence = settings.neglectInfluence;

      // Display settings
      _showOrphanTaskCount = settings.showOrphanTaskCount;
      _showProjectNextTask = settings.showProjectNextTask;

      _recalculateRankedValues(ranking, values);
    } catch (e, s) {
      developer.log(
        '[AllocationSettingsPage] Error loading settings',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _recalculateRankedValues(ValueRanking ranking, List<Value> values) {
    final ranked = <_RankableValue>[];

    // First add ranked items in order
    for (final item in ranking.items) {
      try {
        final value = values.firstWhere((l) => l.id == item.valueId);
        ranked.add(
          _RankableValue(value: value, weight: item.weight, isRanked: true),
        );
      } catch (_) {
        // Value might have been deleted
      }
    }

    // Then add unranked items
    for (final value in values) {
      if (!ranking.items.any((i) => i.valueId == value.id)) {
        ranked.add(
          _RankableValue(value: value, weight: 0, isRanked: false),
        );
      }
    }

    setState(() => _rankedValues = ranked);
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      // Save allocation settings
      final newSettings = AllocationConfig(
        persona: _persona,
        dailyLimit: _dailyTaskLimit,
        urgentTaskBehavior: _urgentTaskBehavior,
        taskUrgencyThresholdDays: _taskUrgencyThresholdDays,
        projectUrgencyThresholdDays: _projectUrgencyThresholdDays,
        urgencyBoostMultiplier: _urgencyBoostMultiplier,
        enableNeglectWeighting: _enableNeglectWeighting,
        neglectLookbackDays: _neglectLookbackDays,
        neglectInfluence: _neglectInfluence,
        showOrphanTaskCount: _showOrphanTaskCount,
        showProjectNextTask: _showProjectNextTask,
      );

      await _settingsRepo.save(SettingsKey.allocation, newSettings);

      // Save value ranking
      final newRankingItems = _rankedValues
          .where((r) => r.isRanked)
          .map(
            (r) => ValueRankItem(
              valueId: r.value.id,
              weight: r.weight,
              sortOrder: _rankedValues.indexOf(r),
            ),
          )
          .toList();

      final newRanking = ValueRanking(items: newRankingItems);
      await _settingsRepo.save(SettingsKey.valueRanking, newRanking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onValueReordered(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _rankedValues.removeAt(oldIndex);
      _rankedValues.insert(newIndex, item);

      // Update isRanked status based on position
      // For now, assume all items in the list are ranked if they have weight > 0
      // But actually, the UI implies dragging to reorder.
      // If we want to support "unranked", we might need a separator or separate list.
      // For this implementation, we'll mark all as ranked if they are in the list
      // and give them a default weight if they were unranked.

      final updatedList = <_RankableValue>[];
      for (var i = 0; i < _rankedValues.length; i++) {
        var val = _rankedValues[i];
        if (!val.isRanked) {
          // Item was moved from unranked to ranked (implicitly)
          val = val.copyWith(isRanked: true, weight: 50); // Default weight
        }
        updatedList.add(val);
      }
      _rankedValues = updatedList;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allocationSettingsTitle),
        actions: [
          if (_hasChanges)
            IconButton(icon: const Icon(Icons.save), onPressed: _saveSettings),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPersonaSection(theme, l10n),
          const SizedBox(height: 24),
          _buildStrategySection(theme, l10n),
          const SizedBox(height: 24),
          _buildValueRankingsSection(theme, l10n),
          const SizedBox(height: 24),
          _buildDisplaySection(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildPersonaSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.personaTitle, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            PersonaSelectionCard(
              selectedPersona: _persona,
              onChanged: (p) {
                setState(() {
                  _persona = p;
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _dailyTaskLimit.toString(),
              decoration: InputDecoration(
                labelText: l10n.dailyTaskLimitLabel,
                helperText: l10n.dailyTaskLimitHelper,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final limit = int.tryParse(value);
                if (limit != null && limit > 0) {
                  setState(() {
                    _dailyTaskLimit = limit;
                    _hasChanges = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySection(ThemeData theme, AppLocalizations l10n) {
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
                Text(l10n.strategyTitle, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UrgentTaskBehavior>(
              value: _urgentTaskBehavior,
              decoration: InputDecoration(
                labelText: l10n.urgentTaskBehaviorLabel,
                border: const OutlineInputBorder(),
              ),
              items: UrgentTaskBehavior.values.map((b) {
                return DropdownMenuItem(
                  value: b,
                  child: Text(_urgentBehaviorName(l10n, b)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _urgentTaskBehavior = value;
                    _hasChanges = true;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _urgentBehaviorDescription(l10n, _urgentTaskBehavior),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.enableNeglectWeightingLabel),
              subtitle: Text(l10n.enableNeglectWeightingHelper),
              value: _enableNeglectWeighting,
              onChanged: (value) {
                setState(() {
                  _enableNeglectWeighting = value;
                  _hasChanges = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySection(ThemeData theme, AppLocalizations l10n) {
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
                Text(l10n.displayTitle, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.showOrphanTaskCountLabel),
              value: _showOrphanTaskCount,
              onChanged: (value) {
                setState(() {
                  _showOrphanTaskCount = value;
                  _hasChanges = true;
                });
              },
            ),
            SwitchListTile(
              title: Text(l10n.showProjectNextTaskLabel),
              value: _showProjectNextTask,
              onChanged: (value) {
                setState(() {
                  _showProjectNextTask = value;
                  _hasChanges = true;
                });
              },
            ),
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
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) {
                  final rankableValue = _rankedValues[index];
                  return EnhancedValueCard.compact(
                    key: ValueKey(rankableValue.value.id),
                    value: rankableValue.value,
                    rank: index + 1,
                    showDragHandle: true,
                    stats: rankableValue.isRanked
                        ? ValueStats(
                            targetPercent: rankableValue.weight.toDouble(),
                            actualPercent: 0,
                            taskCount: 0,
                            projectCount: 0,
                            weeklyTrend: const [],
                          )
                        : null,
                    notRankedMessage: l10n.notRankedDragToRank,
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
    required this.value,
    required this.weight,
    required this.isRanked,
  });

  final Value value;
  final int weight;
  final bool isRanked;

  _RankableValue copyWith({Value? value, int? weight, bool? isRanked}) {
    return _RankableValue(
      value: value ?? this.value,
      weight: weight ?? this.weight,
      isRanked: isRanked ?? this.isRanked,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/app_log.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/presentation/features/next_action/widgets/persona_selection_card.dart';

/// Settings page for configuring task allocation strategy.
class AllocationSettingsPage extends StatefulWidget {
  const AllocationSettingsPage({
    required this.settingsRepository,
    super.key,
  });

  final SettingsRepositoryContract settingsRepository;

  @override
  State<AllocationSettingsPage> createState() => _AllocationSettingsPageState();
}

class _AllocationSettingsPageState extends State<AllocationSettingsPage> {
  SettingsRepositoryContract get _settingsRepo => widget.settingsRepository;

  // Retained for potential future use
  // ignore: unused_field
  AllocationConfig? _allocationConfig;
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

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      AppLog.routine('ui.allocation_settings', 'Loading settings');
      final settings = await _settingsRepo.load(SettingsKey.allocation);
      AppLog.routine(
        'ui.allocation_settings',
        'Loaded allocation: dailyLimit=${settings.dailyLimit}, '
            'persona=${settings.persona}',
      );

      _allocationConfig = settings;

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
    } catch (e, s) {
      AppLog.handle('ui.allocation_settings', 'Error loading settings', e, s);
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

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      // Save allocation settings
      final newSettings = AllocationConfig(
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
      );

      await _settingsRepo.save(SettingsKey.allocation, newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.settingsSaved)),
        );
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.settingsSaveError(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            ...AllocationPersona.values.map(
              (persona) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PersonaSelectionCard(
                  persona: persona,
                  isSelected: _persona == persona,
                  onTap: () {
                    setState(() {
                      _persona = persona;
                      _hasChanges = true;
                    });
                  },
                ),
              ),
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

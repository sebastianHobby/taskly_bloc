# Phase 5: User Settings & Preferences

## AI Implementation Instructions

### Environment Setup
- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each file creation. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

### Phase Goal
Enable users to customize section display settings (grouping, sorting, related data visibility, layout) and persist these preferences.

### Prerequisites
- Phase 0-4 complete (types, services, BLoC, UI, workflows)

---

## Background: Display Settings Model

From Phase 0, we have:

```dart
@freezed
class SectionDisplaySettings with _$SectionDisplaySettings {
  const factory SectionDisplaySettings({
    @Default(RelatedDisplayMode.nested) RelatedDisplayMode relatedDisplayMode,
    GroupByField? groupBy,
    SortConfig? sort,
    LayoutMode? layoutMode,
    @Default({}) Set<String> collapsedGroupIds,
  }) = _SectionDisplaySettings;
}
```

Users need UI to modify these settings per section.

---

## Task 1: Create Display Settings Repository

**File**: `lib/domain/interfaces/section_display_settings_repository_contract.dart`

```dart
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';

/// Repository for persisting user's section display preferences.
abstract class SectionDisplaySettingsRepositoryContract {
  /// Gets display settings for a section.
  /// Returns default settings if none saved.
  Future<SectionDisplaySettings> getSettings({
    required String screenId,
    required String sectionId,
  });

  /// Saves display settings for a section.
  Future<void> saveSettings({
    required String screenId,
    required String sectionId,
    required SectionDisplaySettings settings,
  });

  /// Resets section settings to defaults.
  Future<void> resetSettings({
    required String screenId,
    required String sectionId,
  });

  /// Gets all custom settings for a screen.
  Future<Map<String, SectionDisplaySettings>> getAllSettingsForScreen({
    required String screenId,
  });

  /// Clears all custom settings (restore all defaults).
  Future<void> clearAllSettings();
}
```

---

## Task 2: Implement Settings Repository with SharedPreferences

**File**: `lib/data/repositories/section_display_settings_repository.dart`

```dart
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskly_bloc/domain/interfaces/section_display_settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';

@LazySingleton(as: SectionDisplaySettingsRepositoryContract)
class SectionDisplaySettingsRepository
    implements SectionDisplaySettingsRepositoryContract {
  SectionDisplaySettingsRepository({
    required SharedPreferences sharedPreferences,
  }) : _prefs = sharedPreferences;

  final SharedPreferences _prefs;

  static const _keyPrefix = 'section_display_settings';

  String _buildKey(String screenId, String sectionId) =>
      '${_keyPrefix}_${screenId}_$sectionId';

  @override
  Future<SectionDisplaySettings> getSettings({
    required String screenId,
    required String sectionId,
  }) async {
    final key = _buildKey(screenId, sectionId);
    final json = _prefs.getString(key);

    if (json == null) {
      return const SectionDisplaySettings();
    }

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return SectionDisplaySettings.fromJson(map);
    } catch (e) {
      // Corrupted data, return defaults
      return const SectionDisplaySettings();
    }
  }

  @override
  Future<void> saveSettings({
    required String screenId,
    required String sectionId,
    required SectionDisplaySettings settings,
  }) async {
    final key = _buildKey(screenId, sectionId);
    final json = jsonEncode(settings.toJson());
    await _prefs.setString(key, json);
  }

  @override
  Future<void> resetSettings({
    required String screenId,
    required String sectionId,
  }) async {
    final key = _buildKey(screenId, sectionId);
    await _prefs.remove(key);
  }

  @override
  Future<Map<String, SectionDisplaySettings>> getAllSettingsForScreen({
    required String screenId,
  }) async {
    final prefix = '${_keyPrefix}_${screenId}_';
    final result = <String, SectionDisplaySettings>{};

    for (final key in _prefs.getKeys()) {
      if (key.startsWith(prefix)) {
        final sectionId = key.substring(prefix.length);
        final json = _prefs.getString(key);

        if (json != null) {
          try {
            final map = jsonDecode(json) as Map<String, dynamic>;
            result[sectionId] = SectionDisplaySettings.fromJson(map);
          } catch (e) {
            // Skip corrupted entries
          }
        }
      }
    }

    return result;
  }

  @override
  Future<void> clearAllSettings() async {
    final keysToRemove = _prefs
        .getKeys()
        .where((key) => key.startsWith(_keyPrefix))
        .toList();

    for (final key in keysToRemove) {
      await _prefs.remove(key);
    }
  }
}
```

---

## Task 3: Create Display Settings Sheet Widget

**File**: `lib/presentation/widgets/sections/display_settings_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/section_bloc.dart';

/// Bottom sheet for configuring section display settings.
class DisplaySettingsSheet extends StatefulWidget {
  const DisplaySettingsSheet({
    required this.section,
    required this.currentSettings,
    required this.onSettingsChanged,
    super.key,
  });

  final Section section;
  final SectionDisplaySettings currentSettings;
  final void Function(SectionDisplaySettings) onSettingsChanged;

  /// Shows the settings sheet as a modal bottom sheet.
  static Future<SectionDisplaySettings?> show({
    required BuildContext context,
    required Section section,
    required SectionDisplaySettings currentSettings,
  }) {
    return showModalBottomSheet<SectionDisplaySettings>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _SheetContent(
          section: section,
          currentSettings: currentSettings,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<DisplaySettingsSheet> createState() => _DisplaySettingsSheetState();
}

class _DisplaySettingsSheetState extends State<DisplaySettingsSheet> {
  late SectionDisplaySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
  }

  void _updateSettings(SectionDisplaySettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_shouldShowRelatedSettings())
                _RelatedDataSection(
                  currentMode: _settings.relatedDisplayMode,
                  onModeChanged: (mode) => _updateSettings(
                    _settings.copyWith(relatedDisplayMode: mode),
                  ),
                ),
              if (_shouldShowGroupBy()) ...[
                const SizedBox(height: 16),
                _GroupBySection(
                  section: widget.section,
                  currentGroupBy: _settings.groupBy,
                  onGroupByChanged: (groupBy) => _updateSettings(
                    _settings.copyWith(groupBy: groupBy),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _SortSection(
                section: widget.section,
                currentSort: _settings.sort,
                onSortChanged: (sort) => _updateSettings(
                  _settings.copyWith(sort: sort),
                ),
              ),
              if (_shouldShowLayout()) ...[
                const SizedBox(height: 16),
                _LayoutSection(
                  currentLayout: _settings.layoutMode,
                  onLayoutChanged: (layout) => _updateSettings(
                    _settings.copyWith(layoutMode: layout),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Display Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _updateSettings(const SectionDisplaySettings()),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  bool _shouldShowRelatedSettings() {
    final section = widget.section;
    if (section is! DataSection) return false;

    // Show related settings if section has related data config
    return section.relatedConfig != null;
  }

  bool _shouldShowGroupBy() {
    final section = widget.section;
    return section is DataSection;
  }

  bool _shouldShowLayout() {
    final section = widget.section;
    return section is DataSection;
  }
}

class _SheetContent extends StatefulWidget {
  const _SheetContent({
    required this.section,
    required this.currentSettings,
    required this.scrollController,
  });

  final Section section;
  final SectionDisplaySettings currentSettings;
  final ScrollController scrollController;

  @override
  State<_SheetContent> createState() => _SheetContentState();
}

class _SheetContentState extends State<_SheetContent> {
  late SectionDisplaySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Display Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context, const SectionDisplaySettings()),
                child: const Text('Reset'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, _settings),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
        const Divider(),
        // Content
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              if (_shouldShowRelatedSettings())
                _RelatedDataSection(
                  currentMode: _settings.relatedDisplayMode,
                  onModeChanged: (mode) => setState(() {
                    _settings = _settings.copyWith(relatedDisplayMode: mode);
                  }),
                ),
              if (_shouldShowGroupBy()) ...[
                const SizedBox(height: 24),
                _GroupBySection(
                  section: widget.section,
                  currentGroupBy: _settings.groupBy,
                  onGroupByChanged: (groupBy) => setState(() {
                    _settings = _settings.copyWith(groupBy: groupBy);
                  }),
                ),
              ],
              const SizedBox(height: 24),
              _SortSection(
                section: widget.section,
                currentSort: _settings.sort,
                onSortChanged: (sort) => setState(() {
                  _settings = _settings.copyWith(sort: sort);
                }),
              ),
              if (_shouldShowLayout()) ...[
                const SizedBox(height: 24),
                _LayoutSection(
                  currentLayout: _settings.layoutMode,
                  onLayoutChanged: (layout) => setState(() {
                    _settings = _settings.copyWith(layoutMode: layout);
                  }),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldShowRelatedSettings() {
    final section = widget.section;
    if (section is! DataSection) return false;
    return section.relatedConfig != null;
  }

  bool _shouldShowGroupBy() {
    return widget.section is DataSection;
  }

  bool _shouldShowLayout() {
    return widget.section is DataSection;
  }
}

/// Related data display mode selection
class _RelatedDataSection extends StatelessWidget {
  const _RelatedDataSection({
    required this.currentMode,
    required this.onModeChanged,
  });

  final RelatedDisplayMode currentMode;
  final void Function(RelatedDisplayMode) onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Data',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'How to display related items (tasks in projects, etc.)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<RelatedDisplayMode>(
          segments: const [
            ButtonSegment(
              value: RelatedDisplayMode.nested,
              icon: Icon(Icons.account_tree),
              label: Text('Nested'),
            ),
            ButtonSegment(
              value: RelatedDisplayMode.flat,
              icon: Icon(Icons.list),
              label: Text('Flat'),
            ),
            ButtonSegment(
              value: RelatedDisplayMode.hidden,
              icon: Icon(Icons.visibility_off),
              label: Text('Hidden'),
            ),
          ],
          selected: {currentMode},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onModeChanged(selection.first);
            }
          },
        ),
      ],
    );
  }
}

/// Group by field selection
class _GroupBySection extends StatelessWidget {
  const _GroupBySection({
    required this.section,
    required this.currentGroupBy,
    required this.onGroupByChanged,
  });

  final Section section;
  final GroupByField? currentGroupBy;
  final void Function(GroupByField?) onGroupByChanged;

  @override
  Widget build(BuildContext context) {
    final availableFields = _getAvailableGroupByFields();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group By',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('None'),
              selected: currentGroupBy == null || currentGroupBy == GroupByField.none,
              onSelected: (selected) {
                if (selected) onGroupByChanged(null);
              },
            ),
            ...availableFields.map((field) => ChoiceChip(
                  label: Text(_getFieldLabel(field)),
                  selected: currentGroupBy == field,
                  onSelected: (selected) {
                    if (selected) onGroupByChanged(field);
                  },
                )),
          ],
        ),
      ],
    );
  }

  List<GroupByField> _getAvailableGroupByFields() {
    if (section is! DataSection) return [];

    final dataSection = section as DataSection;
    final config = dataSection.dataConfig;

    return switch (config) {
      TaskDataConfig() => [
          GroupByField.project,
          GroupByField.priority,
          GroupByField.dueDate,
          GroupByField.status,
          GroupByField.label,
        ],
      ProjectDataConfig() => [
          GroupByField.status,
          GroupByField.label,
        ],
      LabelDataConfig() => [
          GroupByField.labelType,
        ],
      ValueDataConfig() => [
          GroupByField.labelType,
        ],
    };
  }

  String _getFieldLabel(GroupByField field) {
    return switch (field) {
      GroupByField.none => 'None',
      GroupByField.project => 'Project',
      GroupByField.priority => 'Priority',
      GroupByField.dueDate => 'Due Date',
      GroupByField.status => 'Status',
      GroupByField.label => 'Label',
      GroupByField.value => 'Value',
      GroupByField.labelType => 'Type',
    };
  }
}

/// Sort configuration
class _SortSection extends StatelessWidget {
  const _SortSection({
    required this.section,
    required this.currentSort,
    required this.onSortChanged,
  });

  final Section section;
  final SortConfig? currentSort;
  final void Function(SortConfig?) onSortChanged;

  @override
  Widget build(BuildContext context) {
    final availableFields = _getAvailableSortFields();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        // Sort field selection
        DropdownButtonFormField<SortField?>(
          decoration: const InputDecoration(
            labelText: 'Sort by',
            border: OutlineInputBorder(),
          ),
          value: currentSort?.field,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Default'),
            ),
            ...availableFields.map((field) => DropdownMenuItem(
                  value: field,
                  child: Text(_getSortFieldLabel(field)),
                )),
          ],
          onChanged: (field) {
            if (field == null) {
              onSortChanged(null);
            } else {
              onSortChanged(SortConfig(
                field: field,
                direction: currentSort?.direction ?? SortDirection.ascending,
              ));
            }
          },
        ),
        const SizedBox(height: 12),
        // Sort direction
        if (currentSort != null)
          SegmentedButton<SortDirection>(
            segments: const [
              ButtonSegment(
                value: SortDirection.ascending,
                icon: Icon(Icons.arrow_upward),
                label: Text('Ascending'),
              ),
              ButtonSegment(
                value: SortDirection.descending,
                icon: Icon(Icons.arrow_downward),
                label: Text('Descending'),
              ),
            ],
            selected: {currentSort!.direction},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                onSortChanged(currentSort!.copyWith(direction: selection.first));
              }
            },
          ),
      ],
    );
  }

  List<SortField> _getAvailableSortFields() {
    if (section is! DataSection) return [];

    final dataSection = section as DataSection;
    final config = dataSection.dataConfig;

    return switch (config) {
      TaskDataConfig() => [
          SortField.name,
          SortField.createdAt,
          SortField.updatedAt,
          SortField.dueDate,
          SortField.priority,
        ],
      ProjectDataConfig() => [
          SortField.name,
          SortField.createdAt,
          SortField.updatedAt,
        ],
      LabelDataConfig() => [
          SortField.name,
          SortField.createdAt,
        ],
      ValueDataConfig() => [
          SortField.name,
          SortField.createdAt,
        ],
    };
  }

  String _getSortFieldLabel(SortField field) {
    return switch (field) {
      SortField.name => 'Name',
      SortField.createdAt => 'Created',
      SortField.updatedAt => 'Updated',
      SortField.dueDate => 'Due Date',
      SortField.priority => 'Priority',
      SortField.order => 'Order',
    };
  }
}

/// Layout mode selection
class _LayoutSection extends StatelessWidget {
  const _LayoutSection({
    required this.currentLayout,
    required this.onLayoutChanged,
  });

  final LayoutMode? currentLayout;
  final void Function(LayoutMode?) onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layout',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<LayoutMode>(
          segments: const [
            ButtonSegment(
              value: LayoutMode.list,
              icon: Icon(Icons.view_list),
              label: Text('List'),
            ),
            ButtonSegment(
              value: LayoutMode.grid,
              icon: Icon(Icons.grid_view),
              label: Text('Grid'),
            ),
            ButtonSegment(
              value: LayoutMode.compact,
              icon: Icon(Icons.view_headline),
              label: Text('Compact'),
            ),
          ],
          selected: {currentLayout ?? LayoutMode.list},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onLayoutChanged(selection.first);
            }
          },
        ),
      ],
    );
  }
}
```

---

## Task 4: Add Settings Button to Section Header

**File**: `lib/presentation/widgets/sections/section_header.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';
import 'package:taskly_bloc/presentation/widgets/sections/display_settings_sheet.dart';

/// Header for a section with title and settings button.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.section,
    required this.displaySettings,
    required this.onSettingsChanged,
    this.trailing,
    super.key,
  });

  final Section section;
  final SectionDisplaySettings displaySettings;
  final void Function(SectionDisplaySettings) onSettingsChanged;
  final Widget? trailing;

  String? get _title {
    return switch (section) {
      DataSection(:final title) => title,
      SupportSection() => null,
      NavigationSection(:final groupTitle) => groupTitle,
      AllocationSection() => 'Next Actions',
    };
  }

  @override
  Widget build(BuildContext context) {
    final title = _title;
    if (title == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
          if (_shouldShowSettings())
            IconButton(
              icon: const Icon(Icons.tune, size: 20),
              onPressed: () => _showSettings(context),
              tooltip: 'Display settings',
            ),
        ],
      ),
    );
  }

  bool _shouldShowSettings() {
    // Only show settings for data sections
    return section is DataSection;
  }

  Future<void> _showSettings(BuildContext context) async {
    final newSettings = await DisplaySettingsSheet.show(
      context: context,
      section: section,
      currentSettings: displaySettings,
    );

    if (newSettings != null) {
      onSettingsChanged(newSettings);
    }
  }
}
```

---

## Task 5: Update SectionBloc to Persist Settings

Update the SectionBloc from Phase 3A to save settings:

**File**: `lib/presentation/features/screens/bloc/section_bloc.dart`

Add to existing SectionBloc:

```dart
// Add repository dependency
@injectable
class SectionBloc extends Bloc<SectionBlocEvent, SectionBlocState> {
  SectionBloc({
    required SectionDataService sectionDataService,
    required SectionDisplaySettingsRepositoryContract displaySettingsRepository,
  })  : _sectionDataService = sectionDataService,
        _displaySettingsRepository = displaySettingsRepository,
        super(const SectionBlocState.initial()) {
    // ... existing handlers
    on<_DisplaySettingsChanged>(_onDisplaySettingsChanged);
  }

  final SectionDisplaySettingsRepositoryContract _displaySettingsRepository;

  Future<void> _onDisplaySettingsChanged(
    _DisplaySettingsChanged event,
    Emitter<SectionBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    // Find and update the section
    final updatedSections = currentState.sections.map((loadedSection) {
      if (loadedSection.section.id == event.sectionId) {
        return loadedSection.copyWith(displaySettings: event.settings);
      }
      return loadedSection;
    }).toList();

    emit(currentState.copyWith(sections: updatedSections));

    // Persist settings
    await _displaySettingsRepository.saveSettings(
      screenId: currentState.screen.id,
      sectionId: event.sectionId,
      settings: event.settings,
    );
  }

  /// Load saved settings when initializing
  Future<SectionDisplaySettings> _loadSettingsForSection(
    String screenId,
    String sectionId,
  ) async {
    return _displaySettingsRepository.getSettings(
      screenId: screenId,
      sectionId: sectionId,
    );
  }
}
```

---

## Task 6: Create Global Preferences Screen

**File**: `lib/presentation/features/settings/view/display_preferences_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/interfaces/section_display_settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';

/// Screen for managing global display preferences.
class DisplayPreferencesScreen extends StatefulWidget {
  const DisplayPreferencesScreen({super.key});

  @override
  State<DisplayPreferencesScreen> createState() =>
      _DisplayPreferencesScreenState();
}

class _DisplayPreferencesScreenState extends State<DisplayPreferencesScreen> {
  late final SectionDisplaySettingsRepositoryContract _repository;
  SectionDisplaySettings _defaults = const SectionDisplaySettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = getIt<SectionDisplaySettingsRepositoryContract>();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    // Load global defaults (stored with special screen ID)
    final settings = await _repository.getSettings(
      screenId: '_global_defaults',
      sectionId: '_defaults',
    );
    setState(() {
      _defaults = settings;
      _loading = false;
    });
  }

  Future<void> _saveDefaults(SectionDisplaySettings settings) async {
    await _repository.saveSettings(
      screenId: '_global_defaults',
      sectionId: '_defaults',
      settings: settings,
    );
    setState(() {
      _defaults = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display Preferences'),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset All Settings?'),
                  content: const Text(
                    'This will reset all display settings to defaults across all screens.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _repository.clearAllSettings();
                await _loadDefaults();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All settings reset')),
                  );
                }
              }
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Default Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'These settings apply to new screens. Individual screens can override these.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 24),
                _DefaultRelatedModeCard(
                  currentMode: _defaults.relatedDisplayMode,
                  onModeChanged: (mode) => _saveDefaults(
                    _defaults.copyWith(relatedDisplayMode: mode),
                  ),
                ),
                const SizedBox(height: 16),
                _DefaultLayoutCard(
                  currentLayout: _defaults.layoutMode ?? LayoutMode.list,
                  onLayoutChanged: (layout) => _saveDefaults(
                    _defaults.copyWith(layoutMode: layout),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DefaultRelatedModeCard extends StatelessWidget {
  const _DefaultRelatedModeCard({
    required this.currentMode,
    required this.onModeChanged,
  });

  final RelatedDisplayMode currentMode;
  final void Function(RelatedDisplayMode) onModeChanged;

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
                const Icon(Icons.account_tree),
                const SizedBox(width: 12),
                Text(
                  'Related Data Display',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...RelatedDisplayMode.values.map((mode) => RadioListTile<RelatedDisplayMode>(
                  title: Text(_getModeTitle(mode)),
                  subtitle: Text(_getModeDescription(mode)),
                  value: mode,
                  groupValue: currentMode,
                  onChanged: (value) {
                    if (value != null) onModeChanged(value);
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _getModeTitle(RelatedDisplayMode mode) {
    return switch (mode) {
      RelatedDisplayMode.nested => 'Nested',
      RelatedDisplayMode.flat => 'Flat',
      RelatedDisplayMode.hidden => 'Hidden',
    };
  }

  String _getModeDescription(RelatedDisplayMode mode) {
    return switch (mode) {
      RelatedDisplayMode.nested => 'Show related items nested under parents',
      RelatedDisplayMode.flat => 'Show related items in a flat list below',
      RelatedDisplayMode.hidden => 'Hide related items',
    };
  }
}

class _DefaultLayoutCard extends StatelessWidget {
  const _DefaultLayoutCard({
    required this.currentLayout,
    required this.onLayoutChanged,
  });

  final LayoutMode currentLayout;
  final void Function(LayoutMode) onLayoutChanged;

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
                const Icon(Icons.view_quilt),
                const SizedBox(width: 12),
                Text(
                  'Default Layout',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...LayoutMode.values.map((layout) => RadioListTile<LayoutMode>(
                  title: Text(_getLayoutTitle(layout)),
                  subtitle: Text(_getLayoutDescription(layout)),
                  value: layout,
                  groupValue: currentLayout,
                  onChanged: (value) {
                    if (value != null) onLayoutChanged(value);
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _getLayoutTitle(LayoutMode layout) {
    return switch (layout) {
      LayoutMode.list => 'List',
      LayoutMode.grid => 'Grid',
      LayoutMode.compact => 'Compact',
    };
  }

  String _getLayoutDescription(LayoutMode layout) {
    return switch (layout) {
      LayoutMode.list => 'Standard list with full details',
      LayoutMode.grid => 'Grid layout for visual overview',
      LayoutMode.compact => 'Compact list with minimal details',
    };
  }
}
```

---

## Task 7: Register Route for Preferences Screen

Update router configuration:

```dart
// In your router configuration
GoRoute(
  path: '/settings/display',
  name: AppRouteName.displayPreferences,
  builder: (context, state) => const DisplayPreferencesScreen(),
),
```

---

## Validation Checklist

After completing all tasks:

1. [ ] Run `flutter analyze` - expect 0 errors, 0 warnings
2. [ ] SectionDisplaySettingsRepository compiles
3. [ ] DisplaySettingsSheet shows and saves settings
4. [ ] Settings persist after app restart
5. [ ] SectionBloc loads saved settings
6. [ ] Global preferences screen works
7. [ ] App launches without errors

---

## Files Created This Phase

| File | Purpose |
|------|---------|
| `lib/domain/interfaces/section_display_settings_repository_contract.dart` | Repository contract |
| `lib/data/repositories/section_display_settings_repository.dart` | SharedPreferences impl |
| `lib/presentation/widgets/sections/display_settings_sheet.dart` | Settings bottom sheet |
| `lib/presentation/widgets/sections/section_header.dart` | Header with settings button |
| `lib/presentation/features/settings/view/display_preferences_screen.dart` | Global preferences |

## Files Modified This Phase

| File | Change |
|------|--------|
| `lib/presentation/features/screens/bloc/section_bloc.dart` | Add settings persistence |
| Router configuration | Add preferences route |
| DI configuration | Register repository |

---

## UX Considerations

### Per-Section vs Global
- **Per-section settings**: Apply to one section on one screen
- **Global defaults**: Apply to new sections that don't have saved settings
- Users can override global defaults per-section

### Settings Discovery
- Gear icon appears in section header for data sections
- Tapping opens bottom sheet with all applicable options
- Changes apply immediately (preview before dismissing)

### Persistence Strategy
- Settings keyed by `screenId + sectionId`
- Global defaults use special `_global_defaults` screen ID
- SharedPreferences for simple, fast access
- Consider Drift table for complex scenarios

---

## Next Phase
Proceed to **Phase 6: Cleanup & Migration** after all validation passes.

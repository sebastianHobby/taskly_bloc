import 'dart:io';

import 'package:material_symbols_icons/material_symbols_metadata.dart' as meta;

const _targetTotal = 400;

const _themeQuotas = <String, int>{
  'work_career': 34,
  'home_family': 34,
  'health_fitness': 34,
  'planning_time': 34,
  'finance_money': 33,
  'learning_growth': 33,
  'social_community': 33,
  'travel_commute': 33,
  'goals_achievement': 33,
  'hobbies_fun': 33,
  'tech_tools': 33,
  'wellness_mindfulness': 33,
};

const _themeKeywords = <String, List<String>>{
  'work_career': [
    'work',
    'business',
    'office',
    'briefcase',
    'meeting',
    'assignment',
    'task',
    'project',
    'document',
    'report',
    'clipboard',
    'calendar',
    'analytics',
    'schedule',
    'rocket',
    'insights',
    'manage',
    'build',
  ],
  'home_family': [
    'home',
    'house',
    'family',
    'household',
    'kitchen',
    'clean',
    'laundry',
    'bed',
    'sofa',
    'shopping',
    'grocery',
    'baby',
    'kids',
    'pet',
    'garden',
  ],
  'health_fitness': [
    'health',
    'fitness',
    'gym',
    'exercise',
    'run',
    'walk',
    'bike',
    'sports',
    'heart',
    'medical',
    'clinic',
    'pill',
    'nutrition',
    'water',
    'sleep',
    'yoga',
  ],
  'finance_money': [
    'money',
    'finance',
    'cash',
    'payment',
    'wallet',
    'bank',
    'card',
    'credit',
    'savings',
    'budget',
    'price',
    'receipt',
    'invoice',
    'tax',
    'coin',
  ],
  'learning_growth': [
    'learn',
    'study',
    'book',
    'school',
    'class',
    'education',
    'college',
    'degree',
    'knowledge',
    'notes',
    'idea',
    'lightbulb',
    'language',
    'code',
  ],
  'social_community': [
    'social',
    'community',
    'group',
    'people',
    'person',
    'team',
    'chat',
    'message',
    'call',
    'share',
    'heart',
    'favorite',
    'celebrate',
    'event',
  ],
  'travel_commute': [
    'travel',
    'commute',
    'trip',
    'map',
    'location',
    'directions',
    'transit',
    'train',
    'bus',
    'flight',
    'plane',
    'car',
    'bike',
    'walk',
    'ticket',
  ],
  'planning_time': [
    'plan',
    'schedule',
    'calendar',
    'time',
    'clock',
    'alarm',
    'timer',
    'reminder',
    'checklist',
    'list',
    'timeline',
    'today',
    'event',
  ],
  'goals_achievement': [
    'goal',
    'target',
    'trophy',
    'flag',
    'milestone',
    'achievement',
    'star',
    'priority',
    'progress',
    'track',
    'badge',
    'check',
  ],
  'hobbies_fun': [
    'hobby',
    'music',
    'art',
    'camera',
    'photo',
    'game',
    'movie',
    'book',
    'palette',
    'craft',
    'sports',
    'outdoor',
    'party',
  ],
  'tech_tools': [
    'tech',
    'tools',
    'settings',
    'build',
    'code',
    'device',
    'computer',
    'laptop',
    'cloud',
    'sync',
    'wifi',
    'security',
    'key',
    'bug',
    'terminal',
  ],
  'wellness_mindfulness': [
    'mind',
    'wellness',
    'meditation',
    'relax',
    'spa',
    'self',
    'mood',
    'happy',
    'smile',
    'sleep',
    'nature',
    'leaf',
    'sun',
  ],
};

void main() {
  final outputFile = File(
    'packages/taskly_ui/lib/src/foundations/icons/'
    'taskly_symbol_icons_generated.dart',
  );
  final reportFile = File('packages/taskly_ui/ICON_CATALOG.md');

  final allEntries = meta.iconMap.entries.toList()
    ..sort(
      (a, b) => b.value.popularity.compareTo(a.value.popularity),
    );

  final result = _selectCuratedIcons(allEntries);
  final selected = result.selected.entries.toList();
  selected.sort(
    (a, b) => b.value.popularity.compareTo(a.value.popularity),
  );

  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE. DO NOT EDIT.')
    ..writeln('// Run `dart run tool/generate_taskly_symbol_icons.dart`.')
    ..writeln()
    ..writeln("import 'package:flutter/widgets.dart';")
    ..writeln("import 'package:material_symbols_icons/symbols.dart';")
    ..writeln(
      "import 'package:taskly_ui/src/foundations/icons/taskly_symbol_icon.dart';",
    )
    ..writeln()
    ..writeln('const List<TasklySymbolIcon> tasklySymbolIcons = [');

  for (final entry in selected) {
    final name = entry.key;
    final icon = 'Symbols.$name';
    final searchText = _escape(_buildSearchText(name, entry.value));
    final popularity = entry.value.popularity;
    buffer
      ..writeln('  TasklySymbolIcon(')
      ..writeln("    name: '$name',")
      ..writeln('    icon: $icon,')
      ..writeln("    searchText: '$searchText',")
      ..writeln('    popularity: $popularity,')
      ..writeln('  ),');
  }

  buffer
    ..writeln('];')
    ..writeln()
    ..writeln('const Map<String, IconData> tasklySymbolIconByName = {');

  for (final entry in selected) {
    final name = entry.key;
    final icon = 'Symbols.$name';
    buffer.writeln("  '$name': $icon,");
  }

  buffer
    ..writeln('};')
    ..writeln();

  outputFile.writeAsStringSync(buffer.toString());
  _writeReport(
    reportFile,
    total: selected.length,
    themeQuotas: _themeQuotas,
    themeByName: result.themeByName,
  );
}

_SelectionResult _selectCuratedIcons(
  List<MapEntry<String, meta.SymbolsMetadata>> allEntries,
) {
  final selected = <String, meta.SymbolsMetadata>{};
  final themeByName = <String, String>{};

  for (final themeEntry in _themeQuotas.entries) {
    final theme = themeEntry.key;
    final quota = themeEntry.value;
    var count = 0;
    for (final entry in allEntries) {
      if (count >= quota) break;
      if (selected.containsKey(entry.key)) continue;
      if (!_matchesTheme(theme, entry.key, entry.value)) continue;
      selected[entry.key] = entry.value;
      themeByName[entry.key] = theme;
      count += 1;
    }
  }

  if (selected.length < _targetTotal) {
    for (final entry in allEntries) {
      if (selected.length >= _targetTotal) break;
      if (selected.containsKey(entry.key)) continue;
      selected[entry.key] = entry.value;
      themeByName[entry.key] = 'other';
    }
  }

  return _SelectionResult(
    selected: selected,
    themeByName: themeByName,
  );
}

bool _matchesTheme(
  String theme,
  String name,
  meta.SymbolsMetadata data,
) {
  final keywords = _themeKeywords[theme] ?? const <String>[];
  if (keywords.isEmpty) return false;

  final searchable = <String>[
    name.replaceAll('_', ' '),
    for (final categoryIndex in data.categories)
      if (categoryIndex >= 0 && categoryIndex < meta.categoryMap.length)
        meta.categoryMap[categoryIndex],
    for (final tagIndex in data.tags)
      if (tagIndex >= 0 && tagIndex < meta.tagMap.length) meta.tagMap[tagIndex],
  ].join(' ').toLowerCase();

  for (final keyword in keywords) {
    if (searchable.contains(keyword)) return true;
  }
  return false;
}

String _buildSearchText(String name, meta.SymbolsMetadata data) {
  final buffer = StringBuffer();
  buffer.write(name.replaceAll('_', ' '));
  for (final tagIndex in data.tags) {
    if (tagIndex < 0 || tagIndex >= meta.tagMap.length) continue;
    buffer.write(' ');
    buffer.write(meta.tagMap[tagIndex]);
  }
  return buffer.toString().toLowerCase();
}

String _escape(String value) {
  return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}

void _writeReport(
  File reportFile, {
  required int total,
  required Map<String, int> themeQuotas,
  required Map<String, String> themeByName,
}) {
  final themeOrder = [
    ...themeQuotas.keys,
    'other',
  ];

  final namesByTheme = <String, List<String>>{
    for (final theme in themeOrder) theme: <String>[],
  };

  for (final entry in themeByName.entries) {
    namesByTheme[entry.value]?.add(entry.key);
  }

  for (final names in namesByTheme.values) {
    names.sort();
  }

  final buffer = StringBuffer()
    ..writeln('# Taskly Icon Catalog (generated)')
    ..writeln()
    ..writeln(
      'Generated by `tool/generate_taskly_symbol_icons.dart`.',
    )
    ..writeln()
    ..writeln('Total icons: $total')
    ..writeln()
    ..writeln('## Theme quotas')
    ..writeln();

  for (final theme in themeQuotas.keys) {
    final quota = themeQuotas[theme]!;
    final count = namesByTheme[theme]?.length ?? 0;
    buffer.writeln('- $theme: $count (quota $quota)');
  }
  final otherCount = namesByTheme['other']?.length ?? 0;
  buffer.writeln('- other: $otherCount');
  buffer.writeln();
  buffer.writeln('## Icons by theme');

  for (final theme in themeOrder) {
    final names = namesByTheme[theme] ?? const [];
    buffer
      ..writeln()
      ..writeln('### $theme (${names.length})')
      ..writeln();
    if (names.isEmpty) {
      buffer.writeln('_none_');
      continue;
    }
    for (var i = 0; i < names.length; i += 8) {
      final slice = names.skip(i).take(8).join(', ');
      buffer.writeln('- $slice');
    }
  }

  reportFile.writeAsStringSync(buffer.toString());
}

final class _SelectionResult {
  _SelectionResult({
    required this.selected,
    required this.themeByName,
  });

  final Map<String, meta.SymbolsMetadata> selected;
  final Map<String, String> themeByName;
}

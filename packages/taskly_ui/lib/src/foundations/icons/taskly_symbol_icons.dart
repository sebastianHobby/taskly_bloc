import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_metadata.dart' as meta;
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_symbols_icons/symbols_map.dart' as symbols_map;

/// Symbol icon entry with precomputed search text.
final class TasklySymbolIcon {
  const TasklySymbolIcon({
    required this.name,
    required this.icon,
    required this.searchText,
    required this.popularity,
  });

  final String name;
  final IconData icon;
  final String searchText;
  final int popularity;
}

final List<TasklySymbolIcon> _symbolIcons = _buildSymbolIcons();
final Map<String, IconData> _symbolIconByName = {
  for (final entry in meta.iconMap.entries)
    entry.key:
        symbols_map.materialSymbolsMap[entry.key] ??
        IconDataOutlined(
          entry.value.codepoint,
          matchTextDirection: entry.value.rtlAutoMirrored,
        ),
};

List<TasklySymbolIcon> get tasklySymbolIcons => _symbolIcons;

IconData? tasklySymbolIconDataFromName(String? name) {
  if (name == null) return null;
  return _symbolIconByName[name];
}

List<TasklySymbolIcon> _buildSymbolIcons() {
  final entries = meta.iconMap.entries.toList()
    ..sort(
      (a, b) => b.value.popularity.compareTo(a.value.popularity),
    );

  return List<TasklySymbolIcon>.unmodifiable([
    for (final entry in entries)
      TasklySymbolIcon(
        name: entry.key,
        icon:
            _symbolIconByName[entry.key] ??
            IconDataOutlined(
              entry.value.codepoint,
              matchTextDirection: entry.value.rtlAutoMirrored,
            ),
        searchText: _buildSearchText(entry.key, entry.value),
        popularity: entry.value.popularity,
      ),
  ]);
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

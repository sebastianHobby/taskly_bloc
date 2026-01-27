import 'package:flutter/widgets.dart';

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

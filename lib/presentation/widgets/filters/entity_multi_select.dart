import 'package:flutter/material.dart';

/// Generic multi-select chips widget for any entity type.
///
/// Provides a consistent UI for selecting multiple items from a list,
/// with type-safe extractors for ID, label, icon, and color.
///
/// Type parameter [T] represents the entity type being selected.
///
/// Example:
/// ```dart
/// EntityMultiSelect<Project>(
///   items: projects,
///   selectedIds: selectedProjectIds,
///   onChanged: (ids) => setState(() => selectedProjectIds = ids),
///   idExtractor: (p) => p.id,
///   labelExtractor: (p) => p.name,
///   iconExtractor: (_) => Icons.folder,
/// )
/// ```
class EntityMultiSelect<T> extends StatelessWidget {
  const EntityMultiSelect({
    required this.items,
    required this.selectedIds,
    required this.onChanged,
    required this.idExtractor,
    required this.labelExtractor,
    this.iconExtractor,
    this.colorExtractor,
    this.emptyText = 'No items available',
    this.noneSelectedText = 'Any',
    super.key,
  });

  /// List of items to display.
  final List<T> items;

  /// Set of currently selected item IDs.
  final Set<String> selectedIds;

  /// Called when selection changes.
  final ValueChanged<Set<String>> onChanged;

  /// Extracts the unique ID from an item.
  final String Function(T item) idExtractor;

  /// Extracts the display label from an item.
  final String Function(T item) labelExtractor;

  /// Optional: Extracts an icon for the item.
  final IconData? Function(T item)? iconExtractor;

  /// Optional: Extracts a color for the item.
  final Color? Function(T item)? colorExtractor;

  /// Text to show when no items are available.
  final String emptyText;

  /// Text to show when no items are selected.
  final String noneSelectedText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Chip(
        avatar: const Icon(Icons.info_outline, size: 18),
        label: Text(emptyText),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final id = idExtractor(item);
        final label = labelExtractor(item);
        final isSelected = selectedIds.contains(id);
        final icon = iconExtractor?.call(item);
        final color = colorExtractor?.call(item);

        Widget? avatar;
        if (icon != null) {
          avatar = Icon(icon, size: 18, color: color);
        } else if (color != null) {
          avatar = _ColorDot(color: color);
        }

        return FilterChip(
          avatar: avatar,
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            final newIds = Set<String>.from(selectedIds);
            if (selected) {
              newIds.add(id);
            } else {
              newIds.remove(id);
            }
            onChanged(newIds);
          },
        );
      }).toList(),
    );
  }
}

/// Small colored dot for color-coded entities without icons.
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
    );
  }
}

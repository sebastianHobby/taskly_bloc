import 'package:flutter/material.dart';
import 'package:taskly_domain/core.dart';

enum SectionEntityViewModeV2 {
  all,
  projects,
  tasks,
}

/// Compact chip-based filter UI for list-style sections.
///
/// This is presentation-only state (ephemeral) and should stay inside the
/// section renderer that owns the section's local UI state.
class SectionFilterBarV2 extends StatelessWidget {
  const SectionFilterBarV2({
    required this.showEntityModePicker,
    required this.entityViewMode,
    required this.onEntityViewModeChanged,
    required this.showValuePicker,
    required this.values,
    required this.selectedValueId,
    required this.onSelectedValueChanged,
    this.showFocusOnlyToggle = false,
    this.focusOnly = false,
    this.onFocusOnlyChanged,
    this.showIncludeFutureStartsToggle = false,
    this.includeFutureStarts = true,
    this.onIncludeFutureStartsChanged,
    super.key,
    this.onClearFilters,
    this.singleLine = false,
  });

  final bool showEntityModePicker;
  final SectionEntityViewModeV2 entityViewMode;
  final ValueChanged<SectionEntityViewModeV2> onEntityViewModeChanged;

  final bool showValuePicker;
  final List<Value> values;
  final String? selectedValueId;
  final ValueChanged<String?> onSelectedValueChanged;

  final bool showFocusOnlyToggle;
  final bool focusOnly;
  final ValueChanged<bool>? onFocusOnlyChanged;

  final bool showIncludeFutureStartsToggle;
  final bool includeFutureStarts;
  final ValueChanged<bool>? onIncludeFutureStartsChanged;

  final VoidCallback? onClearFilters;

  /// When true, render chips in a single horizontally-scrollable row.
  ///
  /// Useful for pinned filter bars where a stable height is preferred.
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!showEntityModePicker &&
        !showValuePicker &&
        !showFocusOnlyToggle &&
        !showIncludeFutureStartsToggle) {
      return const SizedBox.shrink();
    }

    final entityModeLabel = switch (entityViewMode) {
      SectionEntityViewModeV2.all => 'Show: All',
      SectionEntityViewModeV2.projects => 'Show: Projects',
      SectionEntityViewModeV2.tasks => 'Show: Tasks',
    };

    final selectedValueLabel = (selectedValueId == null)
        ? 'Value: All'
        : values
                  .where((v) => v.id == selectedValueId)
                  .map((v) => v.name)
                  .cast<String?>()
                  .firstWhere(
                    (v) => v != null && v.trim().isNotEmpty,
                    orElse: () => 'Selected',
                  ) ??
              'Selected';

    final chips = <Widget>[
      if (showEntityModePicker)
        ActionChip(
          avatar: Icon(
            Icons.view_list,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          label: Text(entityModeLabel),
          onPressed: () async {
            final selected = await _pickEntityViewMode(context);
            if (selected == null) return;
            onEntityViewModeChanged(selected);
          },
        ),
      if (showValuePicker)
        ActionChip(
          avatar: Icon(
            Icons.filter_list,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          label: Text(selectedValueLabel),
          onPressed: () async {
            final selected = await _pickValue(context);
            if (selected == null && selectedValueId == null) return;
            onSelectedValueChanged(selected);
          },
        ),
      if (showFocusOnlyToggle)
        FilterChip(
          avatar: Icon(
            Icons.center_focus_strong,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          label: const Text('Focus only'),
          selected: focusOnly,
          onSelected: onFocusOnlyChanged,
        ),
      if (showIncludeFutureStartsToggle)
        FilterChip(
          avatar: Icon(
            Icons.schedule,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          label: const Text('Include future starts'),
          selected: includeFutureStarts,
          onSelected: onIncludeFutureStartsChanged,
        ),
      if (onClearFilters != null)
        ActionChip(
          avatar: Icon(
            Icons.clear,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          label: const Text('Clear'),
          onPressed: onClearFilters,
        ),
    ];

    if (singleLine) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (i, chip) in chips.indexed) ...[
                if (i != 0) const SizedBox(width: 8),
                chip,
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
    );
  }

  Future<String?> _pickValue(BuildContext context) {
    return showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Value filter',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: selectedValueId == null
                    ? const Icon(Icons.check)
                    : const SizedBox(width: 24),
                title: const Text('All values'),
                onTap: () => Navigator.of(context).pop(null),
              ),
              const Divider(height: 1),
              for (final v in values)
                ListTile(
                  leading: selectedValueId == v.id
                      ? const Icon(Icons.check)
                      : const SizedBox(width: 24),
                  title: Text(v.name),
                  onTap: () => Navigator.of(context).pop(v.id),
                ),
              if (values.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Text(
                    'No values available yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<SectionEntityViewModeV2?> _pickEntityViewMode(BuildContext context) {
    return showModalBottomSheet<SectionEntityViewModeV2?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        Widget row({
          required String title,
          required SectionEntityViewModeV2 mode,
        }) {
          return ListTile(
            leading: entityViewMode == mode
                ? const Icon(Icons.check)
                : const SizedBox(width: 24),
            title: Text(title),
            onTap: () => Navigator.of(context).pop(mode),
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Show',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              row(title: 'All', mode: SectionEntityViewModeV2.all),
              row(title: 'Projects', mode: SectionEntityViewModeV2.projects),
              row(title: 'Tasks', mode: SectionEntityViewModeV2.tasks),
            ],
          ),
        );
      },
    );
  }
}

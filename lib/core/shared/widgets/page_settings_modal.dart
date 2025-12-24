import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/settings.dart';

/// Shows a page settings modal with display options and sort options.
///
/// This modal allows users to configure:
/// - Display settings (e.g., hide/show completed items)
/// - Sort preferences
///
/// Changes are auto-applied via the provided callbacks.
Future<void> showPageSettingsModal({
  required BuildContext context,
  required PageDisplaySettings displaySettings,
  required SortPreferences sortPreferences,
  required List<SortField> availableSortFields,
  required ValueChanged<PageDisplaySettings> onDisplaySettingsChanged,
  required ValueChanged<SortPreferences> onSortPreferencesChanged,
  required String pageTitle,
  bool showCompletedToggle = true,
  bool showNextActionsBannerToggle = false,
}) {
  return showDetailModal<void>(
    context: context,
    childBuilder: (modalContext) => _PageSettingsModalContent(
      displaySettings: displaySettings,
      sortPreferences: sortPreferences,
      availableSortFields: availableSortFields,
      onDisplaySettingsChanged: onDisplaySettingsChanged,
      onSortPreferencesChanged: onSortPreferencesChanged,
      pageTitle: pageTitle,
      showCompletedToggle: showCompletedToggle,
      showNextActionsBannerToggle: showNextActionsBannerToggle,
    ),
  );
}

class _PageSettingsModalContent extends StatefulWidget {
  const _PageSettingsModalContent({
    required this.displaySettings,
    required this.sortPreferences,
    required this.availableSortFields,
    required this.onDisplaySettingsChanged,
    required this.onSortPreferencesChanged,
    required this.pageTitle,
    required this.showCompletedToggle,
    required this.showNextActionsBannerToggle,
  });

  final PageDisplaySettings displaySettings;
  final SortPreferences sortPreferences;
  final List<SortField> availableSortFields;
  final ValueChanged<PageDisplaySettings> onDisplaySettingsChanged;
  final ValueChanged<SortPreferences> onSortPreferencesChanged;
  final String pageTitle;
  final bool showCompletedToggle;
  final bool showNextActionsBannerToggle;

  @override
  State<_PageSettingsModalContent> createState() =>
      _PageSettingsModalContentState();
}

class _PageSettingsModalContentState extends State<_PageSettingsModalContent>
    with SingleTickerProviderStateMixin {
  late List<SortCriterion?> _slotValues;
  late TabController _tabController;
  late PageDisplaySettings _displaySettings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _displaySettings = widget.displaySettings;
    final slotCount = widget.availableSortFields.length.clamp(1, 3);
    _slotValues = List<SortCriterion?>.generate(
      slotCount,
      (index) => index < widget.sortPreferences.criteria.length
          ? widget.sortPreferences.criteria[index]
          : null,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<SortCriterion> _sanitizeSelection() {
    final sanitized = <SortCriterion>[];
    for (final criterion in _slotValues) {
      if (criterion == null) continue;
      if (!widget.availableSortFields.contains(criterion.field)) continue;
      final exists = sanitized.any((c) => c.field == criterion.field);
      if (exists) continue;
      sanitized.add(criterion);
    }
    if (sanitized.isEmpty) {
      sanitized.add(
        SortCriterion(field: widget.availableSortFields.first),
      );
    }
    return sanitized;
  }

  void _emitSortSelection() {
    widget.onSortPreferencesChanged(
      SortPreferences(criteria: _sanitizeSelection()),
    );
  }

  void _updateSlotField(int index, SortField? value) {
    setState(() {
      for (var i = 0; i < _slotValues.length; i++) {
        if (i == index) continue;
        if (_slotValues[i]?.field == value) _slotValues[i] = null;
      }
      if (value == null) {
        _slotValues[index] = null;
      } else {
        final direction =
            _slotValues[index]?.direction ?? SortDirection.ascending;
        _slotValues[index] = SortCriterion(
          field: value,
          direction: direction,
        );
      }
    });
    _emitSortSelection();
  }

  void _updateSlotDirection(int index, SortDirection? value) {
    if (value == null) return;
    setState(() {
      final current = _slotValues[index];
      if (current == null) return;
      _slotValues[index] = current.copyWith(direction: value);
    });
    _emitSortSelection();
  }

  String _fieldLabel(BuildContext context, SortField field) {
    final l10n = context.l10n;
    return switch (field) {
      SortField.name => l10n.sortFieldNameLabel,
      SortField.startDate => l10n.sortFieldStartDateLabel,
      SortField.deadlineDate => l10n.sortFieldDeadlineDateLabel,
      SortField.createdDate => 'Created date',
      SortField.updatedDate => 'Updated date',
    };
  }

  IconData _fieldIcon(SortField field) {
    return switch (field) {
      SortField.name => Icons.sort_by_alpha_rounded,
      SortField.startDate => Icons.calendar_today_rounded,
      SortField.deadlineDate => Icons.flag_rounded,
      SortField.createdDate => Icons.add_circle_outline_rounded,
      SortField.updatedDate => Icons.update_rounded,
    };
  }

  String _slotLabel(BuildContext context, int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.sortSlotPrimaryLabel,
      1 => l10n.sortSlotSecondaryLabel,
      _ => l10n.sortSlotTertiaryLabel,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 600,
        maxHeight: 700,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with improved M3 styling
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.pageTitle} Settings',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customize how content is displayed and sorted',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tab Bar with M3 styling
                TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: theme.textTheme.titleSmall,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.sort_rounded, size: 20),
                      text: 'Sort',
                      height: 64,
                    ),
                    Tab(
                      icon: Icon(Icons.visibility_outlined, size: 20),
                      text: 'Display',
                      height: 64,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Content with smooth transitions
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSortOptionsTab(context),
                _buildDisplayOptionsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayOptionsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Visibility',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.showCompletedToggle)
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  'Hide completed items',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _displaySettings.hideCompleted
                        ? 'Completed items are hidden from view'
                        : 'Completed items shown in separate section',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                value: _displaySettings.hideCompleted,
                onChanged: (value) {
                  final updated = _displaySettings.copyWith(
                    hideCompleted: value,
                  );
                  setState(() {
                    _displaySettings = updated;
                  });
                  widget.onDisplaySettingsChanged(updated);
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _displaySettings.hideCompleted
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          if (widget.showNextActionsBannerToggle) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Banner Notifications',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  'Show banner if next actions are available',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _displaySettings.showNextActionsBanner
                        ? 'Banner shown when next actions are available'
                        : 'Banner hidden',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                value: _displaySettings.showNextActionsBanner,
                onChanged: (value) {
                  final updated = _displaySettings.copyWith(
                    showNextActionsBanner: value,
                  );
                  setState(() {
                    _displaySettings = updated;
                  });
                  widget.onDisplaySettingsChanged(updated);
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _displaySettings.showNextActionsBanner
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSortOptionsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort Priority',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Items are sorted by priority from top to bottom',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sort slots with improved design
          for (var i = 0; i < _slotValues.length; i++) ...[
            _buildSortSlot(context, i),
            if (i < _slotValues.length - 1) const SizedBox(height: 16),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSortSlot(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final criterion = _slotValues[index];
    final isUsed = criterion != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isUsed
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUsed
              ? colorScheme.outlineVariant
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isUsed ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with priority label and clear button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isUsed
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 16,
                        color: isUsed
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _slotLabel(context, index),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isUsed
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isUsed)
                  IconButton.filledTonal(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => _updateSlotField(index, null),
                    tooltip: 'Clear sort criteria',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Field selection with improved chip design
            Text(
              'Sort by',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.availableSortFields.map((field) {
                final isSelected = criterion?.field == field;
                final isDisabled =
                    !isSelected && _slotValues.any((c) => c?.field == field);

                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _fieldIcon(field),
                        size: 18,
                        color: isSelected
                            ? colorScheme.onSecondaryContainer
                            : isDisabled
                            ? colorScheme.onSurface.withValues(alpha: 0.38)
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(_fieldLabel(context, field)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: isDisabled
                      ? null
                      : (selected) {
                          if (selected) {
                            _updateSlotField(index, field);
                          } else {
                            _updateSlotField(index, null);
                          }
                        },
                  backgroundColor: colorScheme.surface,
                  selectedColor: colorScheme.secondaryContainer,
                  checkmarkColor: colorScheme.onSecondaryContainer,
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.secondary
                        : colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  elevation: isSelected ? 1 : 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                );
              }).toList(),
            ),

            // Direction selector with segmented button
            if (isUsed) ...[
              const SizedBox(height: 20),
              Text(
                'Direction',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<SortDirection>(
                segments: const [
                  ButtonSegment<SortDirection>(
                    value: SortDirection.ascending,
                    label: Text('Ascending'),
                    icon: Icon(Icons.arrow_upward_rounded, size: 18),
                  ),
                  ButtonSegment<SortDirection>(
                    value: SortDirection.descending,
                    label: Text('Descending'),
                    icon: Icon(Icons.arrow_downward_rounded, size: 18),
                  ),
                ],
                selected: {criterion.direction},
                onSelectionChanged: (Set<SortDirection> selected) {
                  _updateSlotDirection(index, selected.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

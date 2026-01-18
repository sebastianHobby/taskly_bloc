import 'package:flutter/material.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/screens/tiles/screen_item_tile_builder.dart';
import 'package:taskly_bloc/presentation/screens/templates/widgets/section_filter_bar_v2.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_ui/taskly_ui.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

enum InterleavedListRenderModeV2 {
  flat,
  hierarchyValueProjectTask,
}

class InterleavedListRendererV2 extends StatefulWidget {
  const InterleavedListRendererV2({
    required this.items,
    required this.enrichment,
    required this.params,
    required this.entityStyle,
    super.key,
    this.title,
    this.persistenceKey,
    this.renderMode = InterleavedListRenderModeV2.flat,
    this.pinnedProjectHeaders = false,
    this.singleInboxGroupForNoProjectTasks = false,
  });

  final List<ScreenItem> items;
  final EnrichmentResultV2? enrichment;
  final InterleavedListSectionParamsV2 params;
  final EntityStyleV1 entityStyle;
  final String? title;
  final String? persistenceKey;

  final InterleavedListRenderModeV2 renderMode;
  final bool pinnedProjectHeaders;
  final bool singleInboxGroupForNoProjectTasks;

  @override
  State<InterleavedListRendererV2> createState() =>
      _InterleavedListRendererV2State();
}

class _InterleavedListRendererV2State extends State<InterleavedListRendererV2> {
  String? _inferSingleValueIdFromForValueSources() {
    final taskSources = widget.params.sources.whereType<TaskDataConfig>();
    String? inferred;

    for (final source in taskSources) {
      String? sourceValueId;
      for (final predicate in source.query.filter.shared) {
        if (predicate is! TaskValuePredicate) continue;
        if (predicate.operator != ValueOperator.hasAll) continue;
        if (predicate.valueIds.length != 1) continue;
        sourceValueId = predicate.valueIds.single;
        break;
      }

      if (sourceValueId == null) return null;
      if (inferred == null) {
        inferred = sourceValueId;
      } else if (inferred != sourceValueId) {
        return null;
      }
    }

    return inferred;
  }

  SectionEntityViewModeV2 _entityViewMode = SectionEntityViewModeV2.all;
  String? _selectedValueId;
  bool _focusOnly = false;
  bool _includeFutureStarts = true;
  final Set<String> _collapsedProjectIds = <String>{};

  bool _restoredCollapsedState = false;

  String? get _collapsedProjectsStorageKey {
    final base = widget.persistenceKey;
    if (base == null || base.isEmpty) return null;
    return '$base:collapsedProjects';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_restoredCollapsedState) return;
    final storageKey = _collapsedProjectsStorageKey;
    if (storageKey == null) {
      _restoredCollapsedState = true;
      return;
    }

    final bucket = PageStorage.of(context);
    final stored = bucket.readState(context, identifier: storageKey);
    if (stored is List) {
      _collapsedProjectIds
        ..clear()
        ..addAll(stored.whereType<String>());
    }
    _restoredCollapsedState = true;
  }

  bool _isProjectCollapsed(String projectId) {
    return _collapsedProjectIds.contains(projectId);
  }

  void _persistCollapsedProjects() {
    final storageKey = _collapsedProjectsStorageKey;
    if (storageKey == null) return;

    PageStorage.of(context).writeState(
      context,
      _collapsedProjectIds.toList(growable: false),
      identifier: storageKey,
    );
  }

  void _toggleProjectCollapsed(String projectId) {
    setState(() {
      if (!_collapsedProjectIds.add(projectId)) {
        _collapsedProjectIds.remove(projectId);
      }

      _persistCollapsedProjects();
    });
  }

  void _setProjectsCollapsed({
    required Set<String> projectIds,
    required bool collapsed,
  }) {
    if (projectIds.isEmpty) return;

    setState(() {
      if (collapsed) {
        _collapsedProjectIds.addAll(projectIds);
      } else {
        _collapsedProjectIds.removeAll(projectIds);
      }
      _persistCollapsedProjects();
    });
  }

  Set<String> _collectVisibleProjectIds(List<ScreenItem> items) {
    final ids = <String>{};
    for (final item in items) {
      switch (item) {
        case ScreenItemProject(:final project):
          ids.add(project.id);
        case ScreenItemTask(:final task):
          final projectId = task.projectId;
          if (projectId != null && projectId.isNotEmpty) {
            ids.add(projectId);
          }
        default:
          break;
      }
    }
    return ids;
  }

  ({int taskCount, int projectCount}) _countsFor(List<ScreenItem> items) {
    var taskCount = 0;
    var projectCount = 0;
    for (final item in items) {
      switch (item) {
        case ScreenItemTask():
          taskCount++;
        case ScreenItemProject():
          projectCount++;
        default:
          break;
      }
    }
    return (taskCount: taskCount, projectCount: projectCount);
  }

  String _plural(int count, String singular, String plural) {
    return count == 1 ? singular : plural;
  }

  ({int doneCount, int totalCount}) _taskCompletionCountsFor(
    List<ScreenItem> items,
  ) {
    var doneCount = 0;
    var totalCount = 0;

    for (final item in items) {
      switch (item) {
        case ScreenItemTask(:final task):
          totalCount++;
          if (task.completed) doneCount++;
        default:
          break;
      }
    }

    return (doneCount: doneCount, totalCount: totalCount);
  }

  Widget? _buildStatusLine(BuildContext context, List<ScreenItem> items) {
    final (:taskCount, :projectCount) = _countsFor(items);
    if (taskCount == 0 && projectCount == 0) return null;

    final parts = <String>[];
    if (taskCount > 0) {
      parts.add('$taskCount ${_plural(taskCount, 'task', 'tasks')}');
    }
    if (projectCount > 0) {
      parts.add(
        '$projectCount ${_plural(projectCount, 'project', 'projects')}',
      );
    }

    final scheme = Theme.of(context).colorScheme;

    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final countText = Text(parts.join(' • '), style: labelStyle);

    if (!_isAllocationSnapshotTasksToday) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: countText,
      );
    }

    final visibleProjectIds = _collectVisibleProjectIds(items);
    final showCollapseAll = visibleProjectIds.isNotEmpty;
    final allCollapsed =
        showCollapseAll &&
        visibleProjectIds.every(_collapsedProjectIds.contains);

    final progress = _taskCompletionCountsFor(items);
    final showProgress = progress.totalCount > 0;
    final fraction = showProgress
        ? (progress.doneCount / progress.totalCount).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: countText),
              if (showCollapseAll)
                TextButton.icon(
                  onPressed: () => _setProjectsCollapsed(
                    projectIds: visibleProjectIds,
                    collapsed: !allCollapsed,
                  ),
                  icon: Icon(
                    allCollapsed
                        ? Icons.unfold_more_outlined
                        : Icons.unfold_less_outlined,
                    size: 18,
                  ),
                  label: Text(allCollapsed ? 'Expand all' : 'Collapse all'),
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
                    textStyle: Theme.of(context).textTheme.labelMedium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                color: scheme.primary.withOpacity(0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _countsLabelFor(List<ScreenItem> items) {
    final (:taskCount, :projectCount) = _countsFor(items);
    if (taskCount == 0 && projectCount == 0) return null;

    final parts = <String>[];
    if (taskCount > 0) {
      parts.add('$taskCount ${_plural(taskCount, 'task', 'tasks')}');
    }
    if (projectCount > 0) {
      parts.add(
        '$projectCount ${_plural(projectCount, 'project', 'projects')}',
      );
    }

    return parts.join(' • ');
  }

  bool get _isAllocationSnapshotTasksToday {
    return widget.params.sources.any(
      (c) => c is AllocationSnapshotTasksTodayDataConfig,
    );
  }

  Widget? _buildTodayDateLine(BuildContext context) {
    if (!_isAllocationSnapshotTasksToday) return null;

    final scheme = Theme.of(context).colorScheme;
    final now = getIt<NowService>().nowLocal();
    final label = MaterialLocalizations.of(context).formatFullDate(
      now,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildHeaderSlivers({
    required BuildContext context,
    required String? title,
    required SectionFilterSpecV2? filters,
    required List<Value> availableValues,
    required List<ScreenItem> filteredItems,
  }) {
    // Some screens provide their own header; suppress the section header block
    // (Today/date/status/collapse) for allocation-snapshot lists.
    final suppressHeaderBlock = _isAllocationSnapshotTasksToday;
    final showProjectsOnlyToggle = filters?.enableProjectsOnlyToggle ?? false;
    final showValueDropdown = filters?.enableValueDropdown ?? false;
    final showFocusOnlyToggle = filters?.enableFocusOnlyToggle ?? false;
    final showIncludeFutureStartsToggle =
        filters?.enableIncludeFutureStartsToggle ?? false;
    final showFilters =
        showProjectsOnlyToggle ||
        showValueDropdown ||
        showFocusOnlyToggle ||
        showIncludeFutureStartsToggle;

    final statusLine = suppressHeaderBlock
        ? null
        : _buildStatusLine(context, filteredItems);
    final todayLine = suppressHeaderBlock ? null : _buildTodayDateLine(context);
    final effectiveTitle = suppressHeaderBlock ? null : title;

    final titleBlock = (effectiveTitle == null && statusLine == null)
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (effectiveTitle != null) TasklyHeader(title: effectiveTitle),
                ?todayLine,
                ?statusLine,
              ],
            ),
          );

    if (!showFilters) {
      return [if (titleBlock != null) SliverToBoxAdapter(child: titleBlock)];
    }

    final placement =
        filters?.filterBarPlacement ?? FilterBarPlacementV2.inline;

    // UX-001B: keep filters inline on mobile/tablet, but pin them on desktop
    // (expanded) layouts to reduce scroll churn on list-heavy screens.
    final effectivePlacement =
        (placement == FilterBarPlacementV2.inline && context.isExpandedScreen)
        ? FilterBarPlacementV2.pinned
        : placement;

    if (effectivePlacement == FilterBarPlacementV2.pinned) {
      final reservePinnedSpace = filters?.reservePinnedSpace ?? false;

      String? activeFiltersSummary() {
        final parts = <String>[];

        if (_entityViewMode != SectionEntityViewModeV2.all) {
          parts.add(
            switch (_entityViewMode) {
              SectionEntityViewModeV2.projects => 'Projects',
              SectionEntityViewModeV2.tasks => 'Tasks',
              SectionEntityViewModeV2.all => 'All',
            },
          );
        }

        if (_selectedValueId != null) {
          final label = availableValues
              .where((v) => v.id == _selectedValueId)
              .map((v) => v.name)
              .cast<String?>()
              .firstWhere(
                (v) => v != null && v.trim().isNotEmpty,
                orElse: () => null,
              );
          parts.add('Value: ${label ?? 'Selected'}');
        }

        if (showFocusOnlyToggle && _focusOnly) {
          parts.add('Focus only');
        }

        if (showIncludeFutureStartsToggle && !_includeFutureStarts) {
          parts.add('Future starts hidden');
        }

        if (parts.isEmpty) return null;
        return parts.join(' • ');
      }

      final countsLabel = suppressHeaderBlock
          ? null
          : _countsLabelFor(
              filteredItems,
            );
      final filtersLabel = activeFiltersSummary();
      final summaryText = (countsLabel == null)
          ? filtersLabel
          : (filtersLabel == null
                ? countsLabel
                : '$countsLabel — $filtersLabel');

      return [
        if (titleBlock != null) SliverToBoxAdapter(child: titleBlock),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedFilterBarDelegate(
            summaryText: summaryText,
            showEntityModePicker: showProjectsOnlyToggle,
            showValuePicker: showValueDropdown,
            values: availableValues,
            entityViewMode: _entityViewMode,
            selectedValueId: _selectedValueId,
            onEntityViewModeChanged: (SectionEntityViewModeV2 v) =>
                setState(() => _entityViewMode = v),
            onSelectedValueChanged: (String? v) =>
                setState(() => _selectedValueId = v),
            showFocusOnlyToggle: showFocusOnlyToggle,
            focusOnly: _focusOnly,
            onFocusOnlyChanged: (bool v) => setState(() => _focusOnly = v),
            showIncludeFutureStartsToggle: showIncludeFutureStartsToggle,
            includeFutureStarts: _includeFutureStarts,
            onIncludeFutureStartsChanged: (bool v) =>
                setState(() => _includeFutureStarts = v),
            onClearFilters:
                (_entityViewMode != SectionEntityViewModeV2.all ||
                    _selectedValueId != null ||
                    (showFocusOnlyToggle && _focusOnly) ||
                    (showIncludeFutureStartsToggle && !_includeFutureStarts))
                ? () => setState(() {
                    _entityViewMode = SectionEntityViewModeV2.all;
                    _selectedValueId = null;
                    _focusOnly = false;
                    _includeFutureStarts = true;
                  })
                : null,
            reservePinnedSpace: reservePinnedSpace || context.isExpandedScreen,
          ),
        ),
      ];
    }

    // Inline placement: render title + filters as a single header widget.
    final inlineHeader = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (effectiveTitle != null) TasklyHeader(title: effectiveTitle),
          ?statusLine,
          SectionFilterBarV2(
            showEntityModePicker: showProjectsOnlyToggle,
            entityViewMode: _entityViewMode,
            onEntityViewModeChanged: (SectionEntityViewModeV2 v) =>
                setState(() => _entityViewMode = v),
            showValuePicker: showValueDropdown,
            values: availableValues,
            selectedValueId: _selectedValueId,
            onSelectedValueChanged: (String? v) =>
                setState(() => _selectedValueId = v),
            showFocusOnlyToggle: showFocusOnlyToggle,
            focusOnly: _focusOnly,
            onFocusOnlyChanged: (bool v) => setState(() => _focusOnly = v),
            showIncludeFutureStartsToggle: showIncludeFutureStartsToggle,
            includeFutureStarts: _includeFutureStarts,
            onIncludeFutureStartsChanged: (bool v) =>
                setState(() => _includeFutureStarts = v),
            onClearFilters:
                (_entityViewMode != SectionEntityViewModeV2.all ||
                    _selectedValueId != null ||
                    (showFocusOnlyToggle && _focusOnly) ||
                    (showIncludeFutureStartsToggle && !_includeFutureStarts))
                ? () => setState(() {
                    _entityViewMode = SectionEntityViewModeV2.all;
                    _selectedValueId = null;
                    _focusOnly = false;
                    _includeFutureStarts = true;
                  })
                : null,
            singleLine: false,
          ),
        ],
      ),
    );
    return [SliverToBoxAdapter(child: inlineHeader)];
  }

  bool _isAfterTodayLocal(DateTime date) {
    final now = getIt<NowService>().nowLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    return day.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    const tileBuilder = ScreenItemTileBuilder();
    final items = widget.items;

    final filters = widget.params.filters;
    final showValueDropdown = filters?.enableValueDropdown ?? false;
    final showFocusOnlyToggle = filters?.enableFocusOnlyToggle ?? false;
    final showIncludeFutureStartsToggle =
        filters?.enableIncludeFutureStartsToggle ?? false;
    final valueFilterMode =
        filters?.valueFilterMode ?? ValueFilterModeV2.anyValues;

    final availableValues = showValueDropdown
        ? _collectAvailableValues(items)
        : const <Value>[];

    final filteredItems = _applyFiltersToItems(
      items: items,
      valueFilterMode: valueFilterMode,
      showValueDropdown: showValueDropdown,
      showFocusOnlyToggle: showFocusOnlyToggle,
      showIncludeFutureStartsToggle: showIncludeFutureStartsToggle,
    );

    final headerSlivers = _buildHeaderSlivers(
      context: context,
      title: widget.title,
      filters: filters,
      availableValues: availableValues,
      filteredItems: filteredItems,
    );

    if (filteredItems.isEmpty) {
      final hasActiveFilters =
          _entityViewMode != SectionEntityViewModeV2.all ||
          _selectedValueId != null ||
          (showFocusOnlyToggle && _focusOnly) ||
          (showIncludeFutureStartsToggle && !_includeFutureStarts);

      final includeFutureStartsWouldHelp =
          showIncludeFutureStartsToggle &&
          !_includeFutureStarts &&
          _applyFiltersToItems(
            items: items,
            valueFilterMode: valueFilterMode,
            showValueDropdown: showValueDropdown,
            showFocusOnlyToggle: showFocusOnlyToggle,
            showIncludeFutureStartsToggle: showIncludeFutureStartsToggle,
            includeFutureStartsOverride: true,
          ).isNotEmpty;

      final disablingFocusOnlyWouldHelp =
          showFocusOnlyToggle &&
          _focusOnly &&
          _applyFiltersToItems(
            items: items,
            valueFilterMode: valueFilterMode,
            showValueDropdown: showValueDropdown,
            showFocusOnlyToggle: showFocusOnlyToggle,
            showIncludeFutureStartsToggle: showIncludeFutureStartsToggle,
            focusOnlyOverride: false,
          ).isNotEmpty;

      return _EmptyStateSliverGroup(
        headerSlivers: headerSlivers,
        hasActiveFilters: hasActiveFilters,
        onClearFilters: () => setState(() {
          _entityViewMode = SectionEntityViewModeV2.all;
          _selectedValueId = null;
          _focusOnly = false;
          _includeFutureStarts = true;
        }),
        showEnableFutureStartsAction:
            showIncludeFutureStartsToggle && !_includeFutureStarts,
        onEnableFutureStarts: includeFutureStartsWouldHelp
            ? () => setState(() => _includeFutureStarts = true)
            : null,
        showDisableFocusOnlyAction: showFocusOnlyToggle && _focusOnly,
        onDisableFocusOnly: disablingFocusOnlyWouldHelp
            ? () => setState(() => _focusOnly = false)
            : null,
        onAddTask: hasActiveFilters
            ? null
            : () => EditorLauncher.fromGetIt().openTaskEditor(
                context,
                taskId: null,
                defaultProjectId: null,
                defaultValueIds: null,
                showDragHandle: true,
              ),
      );
    }

    return switch (widget.renderMode) {
      InterleavedListRenderModeV2.flat => SliverMainAxisGroup(
        slivers: [
          ...headerSlivers,
          SliverSeparatedList(
            itemCount: filteredItems.length,
            separatorBuilder: (context, index) => _separatorFor(
              separator: widget.params.separator,
              current: filteredItems[index],
              next: filteredItems[index + 1],
            ),
            itemBuilder: (context, index) => _buildItem(
              context,
              tileBuilder: tileBuilder,
              item: filteredItems[index],
            ),
          ),
        ],
      ),
      InterleavedListRenderModeV2.hierarchyValueProjectTask => _buildHierarchy(
        tileBuilder: tileBuilder,
        headerSlivers: headerSlivers,
        pinnedProjectHeaders: widget.pinnedProjectHeaders,
        singleInboxGroupForNoProjectTasks:
            widget.singleInboxGroupForNoProjectTasks,
        items: filteredItems,
      ),
    };
  }

  List<Value> _collectAvailableValues(List<ScreenItem> items) {
    final byId = <String, Value>{};
    for (final item in items) {
      switch (item) {
        case ScreenItemTask(:final task):
          for (final v in task.effectiveValues) {
            byId[v.id] = v;
          }
        case ScreenItemProject(:final project):
          for (final v in project.values) {
            byId[v.id] = v;
          }
        default:
          break;
      }
    }

    final values = byId.values.toList(growable: false)
      ..sort(_compareValuesByPriorityThenName);
    return values;
  }

  int _compareValuesByPriorityThenName(Value a, Value b) {
    final ap = _priorityRank(a.priority);
    final bp = _priorityRank(b.priority);
    final byP = ap.compareTo(bp);
    if (byP != 0) return byP;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _priorityRank(ValuePriority p) {
    return switch (p) {
      ValuePriority.high => 0,
      ValuePriority.medium => 1,
      ValuePriority.low => 2,
    };
  }

  List<ScreenItem> _applyFiltersToItems({
    required List<ScreenItem> items,
    required ValueFilterModeV2 valueFilterMode,
    required bool showValueDropdown,
    required bool showFocusOnlyToggle,
    required bool showIncludeFutureStartsToggle,
    bool? focusOnlyOverride,
    bool? includeFutureStartsOverride,
  }) {
    final qualifyingValueIdByTaskId =
        widget.enrichment?.qualifyingValueIdByTaskId;
    final isAllocatedByTaskId = widget.enrichment?.isAllocatedByTaskId;

    final focusOnlyEnabled =
        showFocusOnlyToggle && (focusOnlyOverride ?? _focusOnly);
    final effectiveIncludeFutureStarts =
        includeFutureStartsOverride ?? _includeFutureStarts;

    bool taskIsInFocus(ScreenItemTask item) {
      final allocated = isAllocatedByTaskId?[item.task.id] ?? false;
      return allocated || item.task.isPinned;
    }

    final focusProjectIds = focusOnlyEnabled
        ? items
              .whereType<ScreenItemTask>()
              .where(taskIsInFocus)
              .map((t) => t.task.projectId)
              .whereType<String>()
              .where((id) => id.trim().isNotEmpty)
              .toSet()
        : const <String>{};

    bool taskMatchesSelectedValue(ScreenItemTask item) {
      if (!showValueDropdown || _selectedValueId == null) return true;

      // If the renderer is using a "qualifying" value (e.g. allocation/focus
      // enrichment), keep filtering semantics consistent with the grouping.
      final qualifying = qualifyingValueIdByTaskId?[item.task.id];
      if (qualifying != null && qualifying.isNotEmpty) {
        return qualifying == _selectedValueId;
      }

      return switch (valueFilterMode) {
        ValueFilterModeV2.anyValues => item.task.effectiveValues.any(
          (v) => v.id == _selectedValueId,
        ),
        ValueFilterModeV2.primaryOnly =>
          item.task.effectivePrimaryValueId == _selectedValueId,
      };
    }

    bool projectMatchesSelectedValue(ScreenItemProject item) {
      if (!showValueDropdown || _selectedValueId == null) return true;
      return item.project.values.any((v) => v.id == _selectedValueId);
    }

    bool taskMatchesFutureStarts(ScreenItemTask item) {
      if (!showIncludeFutureStartsToggle || effectiveIncludeFutureStarts) {
        return true;
      }
      final start = item.task.startDate;
      return start == null || !_isAfterTodayLocal(start);
    }

    bool projectMatchesFutureStarts(ScreenItemProject item) {
      if (!showIncludeFutureStartsToggle || effectiveIncludeFutureStarts) {
        return true;
      }
      final start = item.project.startDate;
      return start == null || !_isAfterTodayLocal(start);
    }

    bool taskMatchesFocusOnly(ScreenItemTask item) {
      if (!focusOnlyEnabled) return true;
      return taskIsInFocus(item);
    }

    bool projectMatchesFocusOnly(ScreenItemProject item) {
      if (!focusOnlyEnabled) return true;
      return focusProjectIds.contains(item.project.id);
    }

    return items
        .where((item) {
          return switch (item) {
            ScreenItemTask() =>
              _entityViewMode != SectionEntityViewModeV2.projects &&
                  taskMatchesSelectedValue(item) &&
                  taskMatchesFocusOnly(item) &&
                  taskMatchesFutureStarts(item),
            ScreenItemProject() =>
              _entityViewMode != SectionEntityViewModeV2.tasks &&
                  projectMatchesSelectedValue(item) &&
                  projectMatchesFocusOnly(item) &&
                  projectMatchesFutureStarts(item),
            ScreenItemValue() => true,
            _ => true,
          };
        })
        .toList(growable: false);
  }

  Widget _buildItem(
    BuildContext context, {
    required ScreenItemTileBuilder tileBuilder,
    required ScreenItem item,
    Widget? titlePrefix,
    Widget? projectTrailing,
    bool showProjectTrailingProgressLabel = false,
  }) {
    final isInFocus =
        item is ScreenItemTask &&
        (widget.enrichment?.isAllocatedByTaskId[item.task.id] ?? false);
    final prefix =
        titlePrefix ??
        (item is ScreenItemTask ? _titlePrefixForTask(item) : null);
    final valueStats = item is ScreenItemValue
        ? widget.enrichment?.valueStatsByValueId[item.value.id]
        : null;

    final base = tileBuilder.build(
      context,
      item: item,
      entityStyle: widget.entityStyle,
      isInFocus: isInFocus,
      valueStats: valueStats,
      titlePrefix: prefix,
      projectTrailing: projectTrailing,
      showProjectTrailingProgressLabel: showProjectTrailingProgressLabel,
    );

    return base;
  }

  SliverMainAxisGroup _buildHierarchy({
    required ScreenItemTileBuilder tileBuilder,
    required List<Widget> headerSlivers,
    required bool pinnedProjectHeaders,
    required bool singleInboxGroupForNoProjectTasks,
    required List<ScreenItem> items,
  }) {
    final values = items.whereType<ScreenItemValue>().toList(growable: false);
    final projects = items.whereType<ScreenItemProject>().toList(
      growable: false,
    );
    final tasks = items.whereType<ScreenItemTask>().toList();

    final rankByTaskId = widget.enrichment?.allocationRankByTaskId;
    final qualifyingValueIdByTaskIdFromEnrichment =
        widget.enrichment?.qualifyingValueIdByTaskId;
    final inferredValueId = _inferSingleValueIdFromForValueSources();
    final qualifyingValueIdByTaskId =
        (qualifyingValueIdByTaskIdFromEnrichment != null &&
            qualifyingValueIdByTaskIdFromEnrichment.isNotEmpty)
        ? qualifyingValueIdByTaskIdFromEnrichment
        : (inferredValueId == null
              ? null
              : <String, String>{
                  for (final t in tasks) t.task.id: inferredValueId,
                });

    // Allocation snapshots may use rank as a global ordering policy.
    if (_isAllocationSnapshotTasksToday &&
        rankByTaskId != null &&
        rankByTaskId.isNotEmpty) {
      final originalIndexById = <String, int>{
        for (final (i, t) in tasks.indexed) t.task.id: i,
      };
      tasks.sort((a, b) {
        final ar = rankByTaskId[a.task.id];
        final br = rankByTaskId[b.task.id];
        if (ar != null && br != null) {
          final byRank = ar.compareTo(br);
          if (byRank != 0) return byRank;
        } else if (ar != null) {
          return -1;
        } else if (br != null) {
          return 1;
        }

        // Preserve prior ordering when ranks are absent/tied.
        final ai = originalIndexById[a.task.id] ?? 0;
        final bi = originalIndexById[b.task.id] ?? 0;
        return ai.compareTo(bi);
      });
    }

    // Collect embedded values so hierarchy works even when no ScreenItemValue
    // tiles are present in the interleaved result.
    final embeddedValueById = <String, Value>{
      for (final v in values) v.value.id: v.value,
    };

    for (final t in tasks) {
      for (final v in t.task.effectiveValues) {
        embeddedValueById[v.id] = v;
      }
    }

    for (final p in projects) {
      for (final v in p.project.values) {
        embeddedValueById[v.id] = v;
      }
    }

    final projectById = <String, Project>{
      for (final p in projects) p.project.id: p.project,
      // Fallback: tasks can embed their linked project; use it to render
      // a project tile even when no explicit ScreenItemProject exists.
      for (final t in tasks)
        if (t.task.project != null) t.task.project!.id: t.task.project!,
    };

    final tasksByValueId = <String, List<ScreenItemTask>>{};
    final tasksWithoutValue = <ScreenItemTask>[];

    final forcedGroupValueId =
        (widget.params.filters?.enableValueDropdown ?? false)
        ? _selectedValueId
        : null;

    bool isSomedayInboxTask(ScreenItemTask t) {
      // Global Inbox semantics: no project.
      return t.task.projectId == null;
    }

    final allowInboxGroup =
        singleInboxGroupForNoProjectTasks &&
        _selectedValueId == null &&
        _entityViewMode != SectionEntityViewModeV2.projects;
    final inboxTasks = allowInboxGroup
        ? tasks.where(isSomedayInboxTask).toList(growable: false)
        : const <ScreenItemTask>[];
    for (final t in tasks) {
      if (allowInboxGroup && isSomedayInboxTask(t)) {
        continue;
      }
      final qualifyingOverride = qualifyingValueIdByTaskId?[t.task.id];
      final valueIds = forcedGroupValueId != null
          ? <String>{forcedGroupValueId}
          : (qualifyingOverride == null
                ? t.task.effectiveValues.map((v) => v.id).toSet()
                : <String>{qualifyingOverride});
      if (valueIds.isEmpty) {
        tasksWithoutValue.add(t);
        continue;
      }
      for (final valueId in valueIds) {
        (tasksByValueId[valueId] ??= <ScreenItemTask>[]).add(t);
      }
    }

    final projectsByValueId = <String, List<ScreenItemProject>>{};
    final projectsWithoutValue = <ScreenItemProject>[];
    for (final p in projects) {
      final valueIds = forcedGroupValueId != null
          ? <String>{forcedGroupValueId}
          : p.project.values.map((v) => v.id).toSet();
      if (valueIds.isEmpty) {
        projectsWithoutValue.add(p);
        continue;
      }
      for (final valueId in valueIds) {
        (projectsByValueId[valueId] ??= <ScreenItemProject>[]).add(p);
      }
    }

    final slivers = <Widget>[];
    slivers.addAll(headerSlivers);

    // Readability defaults for the value->project->task hierarchy layout.
    // Applies to any screen using value->project grouping (e.g., My Day, Someday).
    const projectBlockGap = 6.0;
    const taskIndent = 16.0;

    if (inboxTasks.isNotEmpty) {
      slivers.add(
        const SliverToBoxAdapter(child: _InlineHeader(title: 'Inbox')),
      );
      slivers.add(
        SliverSeparatedList(
          itemCount: inboxTasks.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _buildItem(
            context,
            tileBuilder: tileBuilder,
            item: inboxTasks[index],
          ),
        ),
      );
    }

    void addValueGroup(String title, String? valueId) {
      final groupProjects = valueId == null
          ? projectsWithoutValue
          : (projectsByValueId[valueId] ?? const <ScreenItemProject>[]);
      final groupTasks = valueId == null
          ? tasksWithoutValue
          : (tasksByValueId[valueId] ?? const <ScreenItemTask>[]);

      if (groupProjects.isEmpty && groupTasks.isEmpty) return;

      final valueColorHex = valueId == null
          ? null
          : embeddedValueById[valueId]?.color;
      slivers.add(
        SliverToBoxAdapter(
          child: _InlineHeader(
            title: title,
            dotColorHex: valueColorHex,
          ),
        ),
      );

      final projectsInGroupById = {
        for (final p in groupProjects) p.project.id: p,
      };

      final tasksByProjectId = <String?, List<ScreenItemTask>>{};
      for (final t in groupTasks) {
        (tasksByProjectId[t.task.projectId] ??= <ScreenItemTask>[]).add(t);
      }

      for (final projectId in projectsInGroupById.keys) {
        final projectItem = projectsInGroupById[projectId]!;
        final rawProjectTasks =
            tasksByProjectId.remove(projectId) ?? const <ScreenItemTask>[];

        // Sort focus tasks to the top within each project, preserving
        // existing ordering within each partition.
        final isAllocatedByTaskId = widget.enrichment?.isAllocatedByTaskId;
        final projectTasks =
            (isAllocatedByTaskId == null ||
                isAllocatedByTaskId.isEmpty ||
                rawProjectTasks.isEmpty)
            ? rawProjectTasks
            : (() {
                final focused = <ScreenItemTask>[];
                final other = <ScreenItemTask>[];
                for (final t in rawProjectTasks) {
                  final isFocus = isAllocatedByTaskId[t.task.id] ?? false;
                  (isFocus ? focused : other).add(t);
                }
                return <ScreenItemTask>[...focused, ...other];
              })();

        final collapsed = _isProjectCollapsed(projectId);

        slivers.add(
          SliverToBoxAdapter(child: SizedBox(height: projectBlockGap)),
        );

        slivers.add(
          SliverSeparatedList(
            itemCount: 1 + (collapsed ? 0 : projectTasks.length),
            separatorBuilder: (context, index) {
              if (index == 0) return SizedBox(height: projectBlockGap);
              return const Divider(height: 1);
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                if (_entityViewMode == SectionEntityViewModeV2.tasks) {
                  return _FallbackProjectHeaderRow(
                    title: projectItem.project.name,
                    count: projectTasks.length,
                    collapsed: collapsed,
                    onToggle: () => _toggleProjectCollapsed(projectId),
                    onOpen: () => Routing.toEntity(
                      context,
                      EntityType.project,
                      projectId,
                    ),
                  );
                }

                return _buildItem(
                  context,
                  tileBuilder: tileBuilder,
                  item: projectItem,
                  projectTrailing: _CollapseChevron(
                    collapsed: collapsed,
                    onPressed: () => _toggleProjectCollapsed(projectId),
                  ),
                  showProjectTrailingProgressLabel: true,
                );
              }
              final tile = _buildItem(
                context,
                tileBuilder: tileBuilder,
                item: projectTasks[index - 1],
              );
              if (taskIndent <= 0) return tile;
              return Padding(
                padding: EdgeInsets.only(left: taskIndent),
                child: tile,
              );
            },
          ),
        );
      }

      final tasksNoProject =
          tasksByProjectId.remove(null) ?? const <ScreenItemTask>[];
      if (tasksNoProject.isNotEmpty) {
        slivers.add(
          pinnedProjectHeaders
              ? SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedHeaderDelegate(title: 'No project'),
                )
              : const SliverToBoxAdapter(
                  child: _InlineHeader(title: 'No project'),
                ),
        );
        slivers.add(
          SliverSeparatedList(
            itemCount: tasksNoProject.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildItem(
              context,
              tileBuilder: tileBuilder,
              item: tasksNoProject[index],
            ),
          ),
        );
      }

      final remainingProjectIds = tasksByProjectId.keys.whereType<String>();
      for (final orphanProjectId in remainingProjectIds) {
        final project = projectById[orphanProjectId];
        final projectTasks =
            tasksByProjectId[orphanProjectId] ?? const <ScreenItemTask>[];
        if (projectTasks.isEmpty) continue;

        final collapsed = _isProjectCollapsed(orphanProjectId);

        final projectTitleFallback = (project?.name.trim().isNotEmpty ?? false)
            ? project!.name
            : (projectTasks
                      .map((t) => t.task.project?.name)
                      .whereType<String>()
                      .map((n) => n.trim())
                      .where((n) => n.isNotEmpty)
                      .cast<String?>()
                      .firstWhere((_) => true, orElse: () => null) ??
                  'Unknown project');

        // Small gap before each project block.
        slivers.add(
          SliverToBoxAdapter(child: SizedBox(height: projectBlockGap)),
        );

        // If we can render a project tile, that becomes the header.
        // If not, render a folder row with count (still navigable by id).
        // In Tasks-only mode, always render the folder header row.
        if ((_entityViewMode == SectionEntityViewModeV2.tasks ||
                project == null) &&
            pinnedProjectHeaders) {
          // Preserve pinned text-header behavior for other screens.
          slivers.add(
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedProjectHeaderDelegate(
                title: projectTitleFallback,
                count: projectTasks.length,
                collapsed: collapsed,
                onToggle: () => _toggleProjectCollapsed(orphanProjectId),
                onOpen: () => Routing.toEntity(
                  context,
                  EntityType.project,
                  orphanProjectId,
                ),
              ),
            ),
          );
          if (!collapsed) {
            slivers.add(
              SliverSeparatedList(
                itemCount: projectTasks.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tile = _buildItem(
                    context,
                    tileBuilder: tileBuilder,
                    item: projectTasks[index],
                  );
                  return Padding(
                    padding: const EdgeInsets.only(left: taskIndent),
                    child: tile,
                  );
                },
              ),
            );
          }
          continue;
        }

        slivers.add(
          SliverSeparatedList(
            itemCount: 1 + (collapsed ? 0 : projectTasks.length),
            separatorBuilder: (context, index) {
              if (index == 0) return SizedBox(height: projectBlockGap);
              return const Divider(height: 1);
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                if (project != null &&
                    _entityViewMode != SectionEntityViewModeV2.tasks) {
                  return _buildItem(
                    context,
                    tileBuilder: tileBuilder,
                    item: ScreenItem.project(
                      project,
                      tileCapabilities:
                          EntityTileCapabilitiesResolver.forProject(project),
                    ),
                    projectTrailing: _CollapseChevron(
                      collapsed: collapsed,
                      onPressed: () => _toggleProjectCollapsed(orphanProjectId),
                    ),
                    showProjectTrailingProgressLabel: true,
                  );
                }

                return _FallbackProjectHeaderRow(
                  title: projectTitleFallback,
                  count: projectTasks.length,
                  collapsed: collapsed,
                  onToggle: () => _toggleProjectCollapsed(orphanProjectId),
                  onOpen: () => Routing.toEntity(
                    context,
                    EntityType.project,
                    orphanProjectId,
                  ),
                );
              }

              final tile = _buildItem(
                context,
                tileBuilder: tileBuilder,
                item: projectTasks[index - 1],
              );
              if (taskIndent <= 0) return tile;
              return Padding(
                padding: EdgeInsets.only(left: taskIndent),
                child: tile,
              );
            },
          ),
        );
      }
    }

    final valueIdsInOrder =
        {
          ...projectsByValueId.keys,
          ...tasksByValueId.keys,
        }.toList(growable: false)..sort((a, b) {
          final av = embeddedValueById[a];
          final bv = embeddedValueById[b];
          if (av == null && bv == null) return a.compareTo(b);
          if (av == null) return 1;
          if (bv == null) return -1;
          return _compareValuesByPriorityThenName(av, bv);
        });

    for (final valueId in valueIdsInOrder) {
      final v = embeddedValueById[valueId];
      addValueGroup(v?.name ?? 'Unknown value', valueId);
    }

    // Hide the "No value" group when a specific value is selected.
    if (_selectedValueId == null) {
      addValueGroup('No value', null);
    }

    return SliverMainAxisGroup(slivers: slivers);
  }

  Widget? _titlePrefixForTask(ScreenItemTask item) {
    final prefixParts = <Widget>[];

    final isInFocus =
        !_isAllocationSnapshotTasksToday &&
        (widget.enrichment?.isAllocatedByTaskId[item.task.id] ?? false);
    if (isInFocus) {
      prefixParts.add(const _InFocusPill());
    }

    final rankByTaskId = widget.enrichment?.allocationRankByTaskId;
    if (_isAllocationSnapshotTasksToday &&
        rankByTaskId != null &&
        rankByTaskId.isNotEmpty) {
      final minRank = rankByTaskId.values.reduce(
        (a, b) => a < b ? a : b,
      );
      final rank = rankByTaskId[item.task.id];
      if (rank != null && rank == minRank) {
        prefixParts.add(const _UpNextPill());
      }
    }

    final showAgendaTagPills = widget.params.enrichment.items.any(
      (i) => i.maybeWhen(agendaTags: (_) => true, orElse: () => false),
    );
    if (!showAgendaTagPills) return null;
    final tag = widget.enrichment?.agendaTagByTaskId[item.task.id];
    if (tag == null) return null;

    final label = switch (tag) {
      AgendaTagV2.starts => 'Starts',
      AgendaTagV2.due => 'Due',
      AgendaTagV2.inProgress => 'Ongoing',
    };

    prefixParts.add(_TagPill(label: label));

    if (prefixParts.isEmpty) return null;
    if (prefixParts.length == 1) return prefixParts.single;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in prefixParts) p,
      ],
    );
  }
}

class _InFocusPill extends StatelessWidget {
  const _InFocusPill();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.center_focus_strong,
            size: 14,
            color: scheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'In Focus',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpNextPill extends StatelessWidget {
  const _UpNextPill();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Up next',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CollapseChevron extends StatelessWidget {
  const _CollapseChevron({
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      tooltip: collapsed ? 'Expand project' : 'Collapse project',
      onPressed: onPressed,
      icon: AnimatedRotation(
        turns: collapsed ? -0.25 : 0,
        duration: const Duration(milliseconds: 160),
        child: Icon(
          Icons.expand_more,
          size: 22,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FallbackProjectHeaderRow extends StatelessWidget {
  const _FallbackProjectHeaderRow({
    required this.title,
    required this.count,
    required this.collapsed,
    required this.onToggle,
    required this.onOpen,
  });

  final String title;
  final int count;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.folder_outlined, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            _CollapseChevron(collapsed: collapsed, onPressed: onToggle),
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _EmptyStateSliverGroup extends StatelessWidget {
  const _EmptyStateSliverGroup({
    required this.headerSlivers,
    required this.hasActiveFilters,
    required this.onClearFilters,
    required this.onAddTask,
    this.showEnableFutureStartsAction = false,
    this.onEnableFutureStarts,
    this.showDisableFocusOnlyAction = false,
    this.onDisableFocusOnly,
  });

  final List<Widget> headerSlivers;
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  final bool showEnableFutureStartsAction;
  final VoidCallback? onEnableFutureStarts;

  final bool showDisableFocusOnlyAction;
  final VoidCallback? onDisableFocusOnly;

  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final title = hasActiveFilters
        ? 'No items match your filters'
        : 'Nothing here yet';

    final body = hasActiveFilters
        ? (showDisableFocusOnlyAction && onDisableFocusOnly != null)
              ? 'Try showing all items instead of focus-only.'
              : (showEnableFutureStartsAction && onEnableFutureStarts != null)
              ? 'Try including future starts to see more.'
              : 'Try clearing filters to see more.'
        : 'This section will populate as you add items.';

    return SliverMainAxisGroup(
      slivers: [
        ...headerSlivers,
        SliverToBoxAdapter(
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: scheme.surfaceContainerHighest.withOpacity(0.35),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    hasActiveFilters ? Icons.filter_alt_off : Icons.inbox,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (hasActiveFilters) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (showDisableFocusOnlyAction &&
                                  onDisableFocusOnly != null)
                                TextButton.icon(
                                  onPressed: onDisableFocusOnly,
                                  icon: const Icon(Icons.view_list_outlined),
                                  label: const Text('Show all'),
                                ),
                              if (showEnableFutureStartsAction &&
                                  onEnableFutureStarts != null)
                                TextButton.icon(
                                  onPressed: onEnableFutureStarts,
                                  icon: const Icon(Icons.schedule),
                                  label: const Text('Show future starts'),
                                ),
                              TextButton.icon(
                                onPressed: onClearFilters,
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear filters'),
                              ),
                            ],
                          ),
                        ],
                        if (!hasActiveFilters && onAddTask != null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: onAddTask,
                              icon: const Icon(Icons.add),
                              label: const Text('Add task'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget _separatorFor({
  required ListSeparatorV2 separator,
  required ScreenItem current,
  required ScreenItem next,
}) {
  return switch (separator) {
    ListSeparatorV2.divider => const Divider(height: 1),
    ListSeparatorV2.spaced8 => const SizedBox(height: 8),
    ListSeparatorV2.interleavedAuto =>
      current is ScreenItemTask && next is ScreenItemTask
          ? const Divider(height: 1)
          : const SizedBox(height: 8),
  };
}

class _InlineHeader extends StatelessWidget {
  const _InlineHeader({required this.title, this.dotColorHex});

  final String title;
  final String? dotColorHex;

  @override
  Widget build(BuildContext context) {
    if (dotColorHex == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
    }

    final dotColor = ColorUtils.fromHexWithThemeFallback(context, dotColorHex);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({required this.title});

  final String title;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      alignment: Alignment.bottomLeft,
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.title != title;
  }
}

class _PinnedFilterBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedFilterBarDelegate({
    required this.summaryText,
    required this.showEntityModePicker,
    required this.entityViewMode,
    required this.onEntityViewModeChanged,
    required this.showValuePicker,
    required this.values,
    required this.selectedValueId,
    required this.onSelectedValueChanged,
    required this.showFocusOnlyToggle,
    required this.focusOnly,
    required this.onFocusOnlyChanged,
    required this.showIncludeFutureStartsToggle,
    required this.includeFutureStarts,
    required this.onIncludeFutureStartsChanged,
    required this.reservePinnedSpace,
    this.onClearFilters,
  });

  final String? summaryText;

  final bool showEntityModePicker;
  final SectionEntityViewModeV2 entityViewMode;
  final ValueChanged<SectionEntityViewModeV2> onEntityViewModeChanged;

  final bool showValuePicker;
  final List<Value> values;
  final String? selectedValueId;
  final ValueChanged<String?> onSelectedValueChanged;

  final bool showFocusOnlyToggle;
  final bool focusOnly;
  final ValueChanged<bool> onFocusOnlyChanged;

  final bool showIncludeFutureStartsToggle;
  final bool includeFutureStarts;
  final ValueChanged<bool> onIncludeFutureStartsChanged;

  final VoidCallback? onClearFilters;
  final bool reservePinnedSpace;

  double get _summaryExtent => summaryText == null ? 0 : 22;

  @override
  double get minExtent => (reservePinnedSpace ? 56 : 48) + _summaryExtent;

  @override
  double get maxExtent => (reservePinnedSpace ? 56 : 48) + _summaryExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      elevation: overlapsContent ? 1 : 0,
      child: Padding(
        padding: EdgeInsets.only(bottom: reservePinnedSpace ? 8 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summaryText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  summaryText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SectionFilterBarV2(
              showEntityModePicker: showEntityModePicker,
              entityViewMode: entityViewMode,
              onEntityViewModeChanged: onEntityViewModeChanged,
              showValuePicker: showValuePicker,
              values: values,
              selectedValueId: selectedValueId,
              onSelectedValueChanged: onSelectedValueChanged,
              showFocusOnlyToggle: showFocusOnlyToggle,
              focusOnly: focusOnly,
              onFocusOnlyChanged: onFocusOnlyChanged,
              showIncludeFutureStartsToggle: showIncludeFutureStartsToggle,
              includeFutureStarts: includeFutureStarts,
              onIncludeFutureStartsChanged: onIncludeFutureStartsChanged,
              onClearFilters: onClearFilters,
              singleLine: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedFilterBarDelegate oldDelegate) {
    return oldDelegate.summaryText != summaryText ||
        oldDelegate.showEntityModePicker != showEntityModePicker ||
        oldDelegate.entityViewMode != entityViewMode ||
        oldDelegate.showValuePicker != showValuePicker ||
        oldDelegate.showFocusOnlyToggle != showFocusOnlyToggle ||
        oldDelegate.focusOnly != focusOnly ||
        oldDelegate.showIncludeFutureStartsToggle !=
            showIncludeFutureStartsToggle ||
        oldDelegate.includeFutureStarts != includeFutureStarts ||
        oldDelegate.selectedValueId != selectedValueId ||
        oldDelegate.onClearFilters != onClearFilters;
  }
}

class _PinnedProjectHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedProjectHeaderDelegate({
    required this.title,
    required this.count,
    required this.collapsed,
    required this.onToggle,
    required this.onOpen,
  });

  final String title;
  final int count;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.folder_outlined, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              _CollapseChevron(collapsed: collapsed, onPressed: onToggle),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedProjectHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.count != count ||
        oldDelegate.collapsed != collapsed;
  }
}

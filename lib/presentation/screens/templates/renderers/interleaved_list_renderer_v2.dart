import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/tiles/screen_item_tile_registry.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/sliver_separated_list.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class InterleavedListRendererV2 extends StatefulWidget {
  const InterleavedListRendererV2({
    required this.data,
    required this.params,
    super.key,
    this.title,
    this.compactTiles = false,
    this.onTaskToggle,
  });

  final DataV2SectionResult data;
  final InterleavedListSectionParamsV2 params;
  final String? title;
  final bool compactTiles;
  final void Function(String, bool?)? onTaskToggle;

  @override
  State<InterleavedListRendererV2> createState() =>
      _InterleavedListRendererV2State();
}

class _InterleavedListRendererV2State extends State<InterleavedListRendererV2> {
  bool _projectsOnly = false;
  String? _selectedValueId;
  final Set<String> _collapsedProjectIds = <String>{};

  bool _isProjectCollapsed(String projectId) {
    return _collapsedProjectIds.contains(projectId);
  }

  void _toggleProjectCollapsed(String projectId) {
    setState(() {
      if (!_collapsedProjectIds.add(projectId)) {
        _collapsedProjectIds.remove(projectId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const registry = ScreenItemTileRegistry();

    if (widget.data.items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final filterSpec = widget.params.filters;
    final showProjectsOnlyToggle =
        filterSpec?.enableProjectsOnlyToggle ?? false;
    final showValueDropdown = filterSpec?.enableValueDropdown ?? false;

    final availableValues = showValueDropdown
        ? _collectAvailableValues(widget.data.items)
        : const <Value>[];

    final header = _buildHeader(
      title: widget.title,
      showProjectsOnlyToggle: showProjectsOnlyToggle,
      showValueDropdown: showValueDropdown,
      availableValues: availableValues,
    );

    final filteredItems = _applyFiltersToItems(
      items: widget.data.items,
      valueFilterMode:
          filterSpec?.valueFilterMode ?? ValueFilterModeV2.anyValues,
      showValueDropdown: showValueDropdown,
    );

    return widget.params.layout.when(
      flatList: (separator) {
        return SliverSeparatedList(
          header: header,
          itemCount: filteredItems.length,
          separatorBuilder: (context, index) => _separatorFor(
            separator: separator,
            current: filteredItems[index],
            next: filteredItems[index + 1],
          ),
          itemBuilder: (context, index) => _buildItem(
            context,
            registry: registry,
            item: filteredItems[index],
          ),
        );
      },
      timelineMonthSections: (_) {
        // Interleaved lists are primarily used for mixed entity groupings.
        // For now, treat timeline grouping as a flat list.
        return SliverSeparatedList(
          header: header,
          itemCount: filteredItems.length,
          separatorBuilder: (context, index) => _separatorFor(
            separator: ListSeparatorV2.interleavedAuto,
            current: filteredItems[index],
            next: filteredItems[index + 1],
          ),
          itemBuilder: (context, index) => _buildItem(
            context,
            registry: registry,
            item: filteredItems[index],
          ),
        );
      },
      hierarchyValueProjectTask:
          (
            pinnedValueHeaders,
            pinnedProjectHeaders,
            singleInboxGroupForNoProjectTasks,
          ) {
            return _buildHierarchy(
              registry: registry,
              header: header,
              pinnedValueHeaders: pinnedValueHeaders,
              pinnedProjectHeaders: pinnedProjectHeaders,
              singleInboxGroupForNoProjectTasks:
                  singleInboxGroupForNoProjectTasks,
              items: filteredItems,
            );
          },
    );
  }

  Widget? _buildHeader({
    required String? title,
    required bool showProjectsOnlyToggle,
    required bool showValueDropdown,
    required List<Value> availableValues,
  }) {
    if (title == null && !showProjectsOnlyToggle && !showValueDropdown) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) TasklyHeader(title: title),
          if (showProjectsOnlyToggle || showValueDropdown)
            _FilterBar(
              projectsOnly: _projectsOnly,
              showProjectsOnlyToggle: showProjectsOnlyToggle,
              selectedValueId: _selectedValueId,
              showValueDropdown: showValueDropdown,
              values: availableValues,
              onProjectsOnlyChanged: (v) => setState(() => _projectsOnly = v),
              onSelectedValueChanged: (v) =>
                  setState(() => _selectedValueId = v),
            ),
        ],
      ),
    );
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
  }) {
    // Decision: when a specific Value is selected, the Inbox group disappears.
    final hideNoProjectTasksForValue =
        showValueDropdown && _selectedValueId != null;

    bool taskMatchesSelectedValue(ScreenItemTask item) {
      if (!showValueDropdown || _selectedValueId == null) return true;
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

    return items
        .where((item) {
          return switch (item) {
            ScreenItemTask() =>
              (!_projectsOnly || item.task.projectId != null) &&
                  (!hideNoProjectTasksForValue ||
                      item.task.projectId != null) &&
                  taskMatchesSelectedValue(item),
            ScreenItemProject() => projectMatchesSelectedValue(item),
            ScreenItemValue() => true,
            _ => true,
          };
        })
        .toList(growable: false);
  }

  Widget _buildItem(
    BuildContext context, {
    required ScreenItemTileRegistry registry,
    required ScreenItem item,
    Widget? titlePrefix,
    Widget? projectTrailing,
    bool showProjectTrailingProgressLabel = false,
  }) {
    final prefix =
        titlePrefix ??
        (item is ScreenItemTask ? _titlePrefixForTask(item) : null);
    final valueStats = item is ScreenItemValue
        ? widget.data.enrichment?.valueStatsByValueId[item.value.id]
        : null;

    return registry.build(
      context,
      item: item,
      onTaskToggle: widget.onTaskToggle,
      compactTiles: widget.compactTiles,
      valueStats: valueStats,
      titlePrefix: prefix,
      projectTrailing: projectTrailing,
      showProjectTrailingProgressLabel: showProjectTrailingProgressLabel,
    );
  }

  SliverMainAxisGroup _buildHierarchy({
    required ScreenItemTileRegistry registry,
    required Widget? header,
    required bool pinnedValueHeaders,
    required bool pinnedProjectHeaders,
    required bool singleInboxGroupForNoProjectTasks,
    required List<ScreenItem> items,
  }) {
    final values = items.whereType<ScreenItemValue>().toList(growable: false);
    final projects = items.whereType<ScreenItemProject>().toList(
      growable: false,
    );
    final tasks = items.whereType<ScreenItemTask>().toList(growable: false);

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

    bool isSomedayInboxTask(ScreenItemTask t) {
      // Someday backlog semantics: "no dates" means start + deadline are null.
      // This inbox group additionally requires no project.
      return t.task.projectId == null &&
          t.task.startDate == null &&
          t.task.deadlineDate == null;
    }

    final allowInboxGroup =
        singleInboxGroupForNoProjectTasks &&
        _selectedValueId == null &&
        !_projectsOnly;
    final inboxTasks = allowInboxGroup
        ? tasks.where(isSomedayInboxTask).toList(growable: false)
        : const <ScreenItemTask>[];
    for (final t in tasks) {
      if (allowInboxGroup && isSomedayInboxTask(t)) {
        continue;
      }
      final valueIds = t.task.effectiveValues.map((v) => v.id).toSet();
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
      final valueIds = p.project.values.map((v) => v.id).toSet();
      if (valueIds.isEmpty) {
        projectsWithoutValue.add(p);
        continue;
      }
      for (final valueId in valueIds) {
        (projectsByValueId[valueId] ??= <ScreenItemProject>[]).add(p);
      }
    }

    final slivers = <Widget>[];
    if (header != null) {
      slivers.add(SliverToBoxAdapter(child: header));
    }

    if (inboxTasks.isNotEmpty) {
      slivers.add(
        pinnedValueHeaders
            ? SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(title: 'Inbox'),
              )
            : const SliverToBoxAdapter(child: _InlineHeader(title: 'Inbox')),
      );
      slivers.add(
        SliverSeparatedList(
          itemCount: inboxTasks.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _buildItem(
            context,
            registry: registry,
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
        pinnedValueHeaders
            ? SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  title: title,
                  dotColorHex: valueColorHex,
                ),
              )
            : SliverToBoxAdapter(
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
        final projectTasks =
            tasksByProjectId.remove(projectId) ?? const <ScreenItemTask>[];

        final collapsed = _isProjectCollapsed(projectId);

        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));

        slivers.add(
          SliverSeparatedList(
            itemCount: 1 + (collapsed ? 0 : projectTasks.length),
            separatorBuilder: (context, index) {
              if (index == 0) return const SizedBox(height: 8);
              return const Divider(height: 1);
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildItem(
                  context,
                  registry: registry,
                  item: projectItem,
                  projectTrailing: _CollapseChevron(
                    collapsed: collapsed,
                    onPressed: () => _toggleProjectCollapsed(projectId),
                  ),
                  showProjectTrailingProgressLabel: true,
                );
              }
              return _buildItem(
                context,
                registry: registry,
                item: projectTasks[index - 1],
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
              registry: registry,
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

        // Match My Day spacing: small gap before each project block.
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));

        // If we can render a project tile, that becomes the header.
        // If not, render a folder row with count (still navigable by id).
        if (project == null && pinnedProjectHeaders) {
          // Preserve pinned text-header behavior for other screens.
          slivers.add(
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(title: projectTitleFallback),
            ),
          );
          if (!collapsed) {
            slivers.add(
              SliverSeparatedList(
                itemCount: projectTasks.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => _buildItem(
                  context,
                  registry: registry,
                  item: projectTasks[index],
                ),
              ),
            );
          }
          continue;
        }

        slivers.add(
          SliverSeparatedList(
            itemCount: 1 + (collapsed ? 0 : projectTasks.length),
            separatorBuilder: (context, index) {
              if (index == 0) return const SizedBox(height: 8);
              return const Divider(height: 1);
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                if (project != null) {
                  return _buildItem(
                    context,
                    registry: registry,
                    item: ScreenItem.project(project),
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

              return _buildItem(
                context,
                registry: registry,
                item: projectTasks[index - 1],
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
    if (widget.params.tiles.task != TaskTileVariant.agenda) return null;
    final tag = widget.data.enrichment?.agendaTagByTaskId[item.task.id];
    if (tag == null) return null;

    final label = switch (tag) {
      AgendaTagV2.starts => 'Starts',
      AgendaTagV2.due => 'Due',
      AgendaTagV2.inProgress => 'In progress',
    };

    return _TagPill(label: label);
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
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      tooltip: collapsed ? 'Expand project' : 'Collapse project',
      onPressed: onPressed,
      icon: AnimatedRotation(
        turns: collapsed ? -0.25 : 0,
        duration: const Duration(milliseconds: 160),
        child: Icon(
          Icons.expand_more,
          size: 20,
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.projectsOnly,
    required this.showProjectsOnlyToggle,
    required this.selectedValueId,
    required this.showValueDropdown,
    required this.values,
    required this.onProjectsOnlyChanged,
    required this.onSelectedValueChanged,
  });

  final bool projectsOnly;
  final bool showProjectsOnlyToggle;
  final String? selectedValueId;
  final bool showValueDropdown;
  final List<Value> values;
  final ValueChanged<bool> onProjectsOnlyChanged;
  final ValueChanged<String?> onSelectedValueChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withOpacity(0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showProjectsOnlyToggle)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Projects only',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: projectsOnly,
                    onChanged: onProjectsOnlyChanged,
                  ),
                ],
              ),
            if (showProjectsOnlyToggle && showValueDropdown)
              const SizedBox(height: 8),
            if (showValueDropdown)
              DropdownButtonFormField<String?>(
                value: selectedValueId,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All values'),
                  ),
                  ...values.map(
                    (v) => DropdownMenuItem<String?>(
                      value: v.id,
                      child: Text(v.name),
                    ),
                  ),
                ],
                onChanged: onSelectedValueChanged,
              ),
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
  _PinnedHeaderDelegate({required this.title, this.dotColorHex});

  final String title;
  final String? dotColorHex;

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
    if (dotColorHex == null) {
      return Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
        alignment: Alignment.bottomLeft,
        child: Text(title, style: theme.textTheme.titleMedium),
      );
    }

    final dotColor = ColorUtils.fromHexWithThemeFallback(context, dotColorHex);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      alignment: Alignment.bottomLeft,
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

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.title != title;
  }
}

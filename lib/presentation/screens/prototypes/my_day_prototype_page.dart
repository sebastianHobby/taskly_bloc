import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/allocation_alerts_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/check_in_summary_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_focus_mode_required_page.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';

enum _PrototypePalette {
  sageInk,
  slateIndigo,
}

class MyDayPrototypePage extends StatefulWidget {
  const MyDayPrototypePage({super.key});

  @override
  State<MyDayPrototypePage> createState() => _MyDayPrototypePageState();
}

class _MyDayPrototypePageState extends State<MyDayPrototypePage> {
  _PrototypePalette _palette = _PrototypePalette.sageInk;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Theme(
      data: _prototypeTheme(
        palette: _palette,
        brightness: brightness,
      ),
      child: BlocProvider(
        create: (context) =>
            ScreenBloc(
              screenRepository: getIt(),
              interpreter: getIt<ScreenDataInterpreter>(),
              performanceLogger: getIt<PerformanceLogger>(),
            )..add(
              ScreenEvent.load(
                definition: SystemScreenDefinitions.myDay,
              ),
            ),
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<ScreenBloc, ScreenState>(
              builder: (context, state) {
                final data = switch (state) {
                  ScreenLoadedState(:final data) => data,
                  _ => null,
                };

                if (state is ScreenLoadingState || data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ScreenErrorState) {
                  return const Center(child: Text('Failed to load My Day.'));
                }

                final sections = data.sections;
                if (sections.length == 1 &&
                    sections.first.templateId ==
                        SectionTemplateId.myDayFocusModeRequired) {
                  return const MyDayFocusModeRequiredPage();
                }

                final checkIn = sections.firstWhereOrNull(
                  (s) => s.templateId == SectionTemplateId.checkInSummary,
                );

                final alerts = sections.firstWhereOrNull(
                  (s) => s.templateId == SectionTemplateId.allocationAlerts,
                );

                final allocation = sections.firstWhereOrNull(
                  (s) => s.templateId == SectionTemplateId.allocation,
                );

                final allocationData = allocation?.data;
                final allocationResult =
                    allocationData is AllocationSectionResult
                    ? allocationData
                    : null;

                final allocationUi = allocationResult == null
                    ? null
                    : _AllocationUiModel.fromAllocation(allocationResult);

                return CustomScrollView(
                  slivers: [
                    _PrototypeHeaderSliver(
                      palette: _palette,
                      onPaletteChanged: (value) {
                        setState(() => _palette = value);
                      },
                    ),
                    if (allocationUi != null) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: _FocusSummaryCard(data: allocationUi),
                        ),
                      ),
                    ],
                    if (checkIn?.data case final CheckInSummarySectionResult d)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: _ReviewsDueBanner(
                            count: d.dueReviews.length,
                            hasOverdue: d.hasOverdue,
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                builder: (context) {
                                  return SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        16,
                                      ),
                                      child: CheckInSummarySectionRenderer(
                                        data: d,
                                        title: checkIn?.title,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    if (alerts?.data case final AllocationAlertsSectionResult d)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: _CardSection(
                            child: AllocationAlertsSectionRenderer(
                              data: d,
                              title: alerts?.title,
                            ),
                          ),
                        ),
                      ),
                    if (allocationUi != null)
                      _ValuesAllocationSliver(
                        data: allocationUi,
                      ),
                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: 80),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

ThemeData _prototypeTheme({
  required _PrototypePalette palette,
  required Brightness brightness,
}) {
  final seed = switch (palette) {
    _PrototypePalette.sageInk => const Color(0xFF2F5D50),
    _PrototypePalette.slateIndigo => const Color(0xFF3B4A6B),
  };

  final baseScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );

  final scheme = switch (palette) {
    _PrototypePalette.sageInk => baseScheme.copyWith(
      secondary: const Color(0xFF6C7A89),
      tertiary: const Color(0xFFB08968),
    ),
    _PrototypePalette.slateIndigo => baseScheme.copyWith(
      secondary: const Color(0xFF2A9D8F),
      tertiary: const Color(0xFFB08968),
    ),
  };

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
  );

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    appBarTheme: base.appBarTheme.copyWith(
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: base.cardTheme.copyWith(
      surfaceTintColor: Colors.transparent,
    ),
  );
}

class _PrototypeHeaderSliver extends StatelessWidget {
  const _PrototypeHeaderSliver({
    required this.palette,
    required this.onPaletteChanged,
  });

  final _PrototypePalette palette;
  final ValueChanged<_PrototypePalette> onPaletteChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final now = DateTime.now();
    final dateText = DateFormat('EEEE, MMMM d').format(now);

    return SliverAppBar.large(
      pinned: true,
      backgroundColor: colorScheme.surface,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Day',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _PaletteToggle(
            value: palette,
            onChanged: onPaletteChanged,
          ),
        ),
      ],
    );
  }
}

class _PaletteToggle extends StatelessWidget {
  const _PaletteToggle({required this.value, required this.onChanged});

  final _PrototypePalette value;
  final ValueChanged<_PrototypePalette> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_PrototypePalette>(
      segments: const [
        ButtonSegment(
          value: _PrototypePalette.sageInk,
          label: Text('Sage'),
        ),
        ButtonSegment(
          value: _PrototypePalette.slateIndigo,
          label: Text('Slate'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _FocusSummaryCard extends StatelessWidget {
  const _FocusSummaryCard({required this.data});

  final _AllocationUiModel data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final total = data.totalTaskCount;
    final done = data.completedTaskCount;

    return _CardSection(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$done/$total done',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Text(
                  '${data.projectCount} projects'
                  '${data.excludedCount > 0 ? ' • ${data.excludedCount} excluded' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsDueBanner extends StatelessWidget {
  const _ReviewsDueBanner({
    required this.count,
    required this.hasOverdue,
    required this.onTap,
  });

  final int count;
  final bool hasOverdue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = hasOverdue ? cs.errorContainer : cs.secondaryContainer;
    final fg = hasOverdue ? cs.onErrorContainer : cs.onSecondaryContainer;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                hasOverdue ? Icons.warning_amber_rounded : Icons.schedule,
                color: fg,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count reviews due',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: fg.withOpacity(0.9)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValuesAllocationSliver extends StatelessWidget {
  const _ValuesAllocationSliver({required this.data});

  final _AllocationUiModel data;

  @override
  Widget build(BuildContext context) {
    if (data.requiresValueSetup) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Values required to generate today's focus."),
        ),
      );
    }

    if (data.totalTaskCount == 0) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No tasks allocated for today.'),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          ..._buildByValue(context),
        ]),
      ),
    );
  }

  List<Widget> _buildByValue(BuildContext context) {
    final sections = data.values;

    if (sections.isEmpty) {
      return [
        _ValueSectionCard(
          title: 'Unassigned',
          pinnedTasks: data.unassignedPinnedTasks,
          tasks: data.unassignedTasks,
        ),
        const SizedBox(height: 12),
      ];
    }

    return [
      for (final section in sections) ...[
        _ValueSectionCard(
          title: section.valueName,
          pinnedTasks: section.pinnedTasks,
          tasks: section.tasks,
        ),
        const SizedBox(height: 12),
      ],
      if (data.unassignedPinnedTasks.isNotEmpty ||
          data.unassignedTasks.isNotEmpty) ...[
        _ValueSectionCard(
          title: 'Unassigned',
          pinnedTasks: data.unassignedPinnedTasks,
          tasks: data.unassignedTasks,
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _ValueSectionCard extends StatelessWidget {
  const _ValueSectionCard({
    required this.title,
    required this.pinnedTasks,
    required this.tasks,
  });

  final String title;
  final List<Task> pinnedTasks;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final uniqueTasks = {
      for (final t in [...pinnedTasks, ...tasks]) t.id: t,
    }.values.toList(growable: false);

    final done = uniqueTasks.where((t) => t.completed).length;
    final total = uniqueTasks.length;

    return _CardSection(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$done/$total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (pinnedTasks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.push_pin,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pinned',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < pinnedTasks.length; i++) ...[
                TaskView(
                  task: pinnedTasks[i],
                  onCheckboxChanged: (task, value) async {
                    final actionService = getIt<EntityActionService>();
                    if (value ?? false) {
                      await actionService.completeTask(task.id);
                    } else {
                      await actionService.uncompleteTask(task.id);
                    }
                  },
                ),
                if (i != pinnedTasks.length - 1) const Divider(height: 12),
              ],
              if (tasks.isNotEmpty) const Divider(height: 20),
            ] else
              const SizedBox(height: 8),
            for (var i = 0; i < tasks.length; i++) ...[
              TaskView(
                task: tasks[i],
                onCheckboxChanged: (task, value) async {
                  final actionService = getIt<EntityActionService>();
                  if (value ?? false) {
                    await actionService.completeTask(task.id);
                  } else {
                    await actionService.uncompleteTask(task.id);
                  }
                },
              ),
              if (i != tasks.length - 1) const Divider(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _AllocationUiModel {
  const _AllocationUiModel({
    required this.requiresValueSetup,
    required this.excludedCount,
    required this.completedTaskCount,
    required this.totalTaskCount,
    required this.projectCount,
    required this.values,
    required this.unassignedPinnedTasks,
    required this.unassignedTasks,
  });

  factory _AllocationUiModel.fromAllocation(AllocationSectionResult data) {
    final allTasks = <Task>[
      ...data.allocatedTasks,
      ...data.pinnedTasks.map((p) => p.task),
    ];

    final unique = {
      for (final t in allTasks) t.id: t,
    }.values.toList(growable: false);

    final completed = unique.where((t) => t.completed).length;
    final projectCount = unique
        .map((t) => t.projectId)
        .whereType<String>()
        .toSet()
        .length;

    final pinnedByValueId = <String, List<Task>>{};
    final unassignedPinned = <Task>[];

    for (final pinned in data.pinnedTasks) {
      final task = pinned.task;
      final valueId = task.primaryValueId;
      if (valueId == null || valueId.isEmpty) {
        unassignedPinned.add(task);
      } else {
        (pinnedByValueId[valueId] ??= []).add(task);
      }
    }

    final groups =
        data.tasksByValue.values
            .where(
              (g) =>
                  g.tasks.isNotEmpty ||
                  (pinnedByValueId[g.valueId]?.isNotEmpty ?? false),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final prioCompare = _priorityRank(
              a.valuePriority,
            ).compareTo(_priorityRank(b.valuePriority));
            if (prioCompare != 0) return prioCompare;
            final weightCompare = b.weight.compareTo(a.weight);
            if (weightCompare != 0) return weightCompare;
            return a.valueName.compareTo(b.valueName);
          });

    final values = <_ValueSectionUi>[];

    for (final group in groups) {
      final pinned = pinnedByValueId[group.valueId] ?? const <Task>[];
      final tasks = group.tasks.map((t) => t.task).toList(growable: false);

      final uniqueTasks = {
        for (final t in [...pinned, ...tasks]) t.id: t,
      }.values;
      final done = uniqueTasks.where((t) => t.completed).length;
      final total = uniqueTasks.length;

      values.add(
        _ValueSectionUi(
          valueId: group.valueId,
          valueName: group.valueName,
          pinnedTasks: pinned,
          tasks: tasks,
          done: done,
          total: total,
        ),
      );
    }

    final unassignedAllocated = <Task>[];
    if (data.tasksByValue.isEmpty && data.allocatedTasks.isNotEmpty) {
      unassignedAllocated.addAll(data.allocatedTasks);
    } else {
      for (final task in data.allocatedTasks) {
        final valueId = task.primaryValueId;
        if (valueId == null || valueId.isEmpty) {
          unassignedAllocated.add(task);
        }
      }
    }

    return _AllocationUiModel(
      requiresValueSetup: data.requiresValueSetup,
      excludedCount: data.excludedCount,
      completedTaskCount: completed,
      totalTaskCount: unique.length,
      projectCount: projectCount,
      values: values,
      unassignedPinnedTasks: unassignedPinned,
      unassignedTasks: {
        for (final t in unassignedAllocated) t.id: t,
      }.values.toList(growable: false),
    );
  }

  final bool requiresValueSetup;
  final int excludedCount;
  final int completedTaskCount;
  final int totalTaskCount;
  final int projectCount;
  final List<_ValueSectionUi> values;
  final List<Task> unassignedPinnedTasks;
  final List<Task> unassignedTasks;
}

class _ValueSectionUi {
  const _ValueSectionUi({
    required this.valueId,
    required this.valueName,
    required this.pinnedTasks,
    required this.tasks,
    required this.done,
    required this.total,
  });

  final String valueId;
  final String valueName;
  final List<Task> pinnedTasks;
  final List<Task> tasks;
  final int done;
  final int total;
}

int _priorityRank(ValuePriority p) => switch (p) {
  ValuePriority.high => 0,
  ValuePriority.medium => 1,
  ValuePriority.low => 2,
};

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

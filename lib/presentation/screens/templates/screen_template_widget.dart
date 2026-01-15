import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_repository_contract.dart'
    as attention_repo_v2;
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/screens/language/models/app_bar_action.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/presentation/features/browse/view/browse_hub_screen.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_hub_page.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/bloc/focus_setup_bloc.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/view/focus_setup_wizard_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/presentation/features/attention/view/attention_inbox_page.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_banner_bloc.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_support_section_widgets.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/add_value_fab.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_header_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_focus_mode_required_page.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

/// Switchboard for rendering a typed [ScreenTemplateSpec].
class ScreenTemplateWidget extends StatelessWidget {
  const ScreenTemplateWidget({
    required this.data,
    super.key,
  });

  final ScreenSpecData data;

  @override
  Widget build(BuildContext context) {
    return data.template.when(
      standardScaffoldV1: () => _StandardScaffoldV1Template(data: data),
      reviewInbox: () => const AttentionInboxPage(),
      settingsMenu: () => const SettingsScreen(),
      trackerManagement: () => const _PlaceholderTemplate(
        title: 'Trackers',
        message: 'Tracker management is being rebuilt.',
      ),
      statisticsDashboard: () => const Scaffold(
        body: Center(
          child: Text('Statistics dashboard not implemented yet.'),
        ),
      ),
      journalHub: () => const JournalHubPage(),
      journalTimeline: () => const _PlaceholderTemplate(
        title: 'Journal',
        message: 'Journal is being rebuilt into a hub.',
      ),
      allocationSettings: () => BlocProvider(
        create: (_) => FocusSetupBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          attentionRepository:
              getIt<attention_repo_v2.AttentionRepositoryContract>(),
          valueRepository: getIt(),
        )..add(const FocusSetupEvent.started()),
        child: const FocusSetupWizardPage(),
      ),
      attentionRules: () => BlocProvider(
        create: (_) => FocusSetupBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          attentionRepository:
              getIt<attention_repo_v2.AttentionRepositoryContract>(),
          valueRepository: getIt(),
        )..add(const FocusSetupEvent.started()),
        child: const FocusSetupWizardPage(),
      ),
      focusSetupWizard: () => BlocProvider(
        create: (_) => FocusSetupBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          attentionRepository:
              getIt<attention_repo_v2.AttentionRepositoryContract>(),
          valueRepository: getIt(),
        )..add(const FocusSetupEvent.started()),
        child: const FocusSetupWizardPage(),
      ),
      browseHub: () => const BrowseHubScreen(),
      myDayFocusModeRequired: () => const MyDayFocusModeRequiredPage(),
    );
  }
}

class _PlaceholderTemplate extends StatelessWidget {
  const _PlaceholderTemplate({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _StandardScaffoldV1Template extends StatelessWidget {
  const _StandardScaffoldV1Template({required this.data});

  final ScreenSpecData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = data.spec;
    final isMyDay = spec.screenKey == 'my_day';

    final myDayProgress = isMyDay
        ? _myDayTaskProgress(data.sections.primary)
        : null;

    final description = spec.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    final headerSections = isMyDay
        ? data.sections.header
              .where((s) => s.templateId != SectionTemplateId.attentionBannerV1)
              .toList(growable: false)
        : data.sections.header;

    final appBarActions = _buildAppBarActions(context, spec);
    final fab = _buildFab(spec);

    final slivers = <Widget>[
      if (isMyDay) _MyDayMyFocusCardSliver(progress: myDayProgress),
      ...headerSections.map(
        (s) => _ModuleSliver(section: s, screenKey: spec.screenKey),
      ),
      ..._buildPrimarySlivers(context),
    ];

    String smartGreeting(DateTime now) {
      final hour = now.hour;

      if (hour >= 5 && hour < 12) return 'Good morning';
      if (hour >= 12 && hour < 18) return 'Good afternoon';
      return 'Good evening';
    }

    final scaffold = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: isMyDay || hasDescription ? 72 : null,
        title: isMyDay
            ? Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final greeting = smartGreeting(now);
                  final dateLabel = MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(now);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spec.name),
                      Text(
                        '$greeting • $dateLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spec.name),
                  if (hasDescription)
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
        actions: appBarActions,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: CustomScrollView(slivers: slivers),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: fab ?? const SizedBox.shrink(key: ValueKey('no-fab')),
      ),
    );

    if (!isMyDay) return scaffold;

    return BlocProvider<MyDayHeaderBloc>(
      create: (_) => getIt<MyDayHeaderBloc>()..add(const MyDayHeaderStarted()),
      child: BlocListener<MyDayHeaderBloc, MyDayHeaderState>(
        listenWhen: (previous, current) {
          return previous.navRequestId != current.navRequestId &&
              current.nav == MyDayHeaderNav.openFocusSetupWizard;
        },
        listener: (context, state) {
          Routing.toScreenKey(context, 'focus_setup');
        },
        child: scaffold,
      ),
    );
  }

  List<Widget> _buildPrimarySlivers(BuildContext context) {
    final spec = data.spec;
    final primary = data.sections.primary;

    if (spec.screenKey == 'my_day') {
      final attentionState = context.watch<AttentionBannerBloc>().state;
      const myDayPrimaryTitle = "Today's Focus";

      if (primary.length == 1) {
        final section = primary.single;
        final listData = section.data;
        if (listData is DataV2SectionResult && listData.items.isEmpty) {
          final hasAttention = attentionState.totalCount > 0;

          return [
            _MyDayEmptyStateSliver(
              title: myDayPrimaryTitle,
              hasAttention: hasAttention,
              onReviewInbox: hasAttention
                  ? () => Routing.toScreenKey(
                      context,
                      AttentionBannerBloc.overflowScreenKey,
                    )
                  : null,
              onAddTask: hasAttention ? null : () => Routing.toTaskNew(context),
            ),
          ];
        }
      }

      final titled = primary
          .map((s) => s.copyWith(title: myDayPrimaryTitle))
          .toList(growable: false);
      return titled
          .map((s) => _ModuleSliver(section: s, screenKey: spec.screenKey))
          .toList(growable: false);
    }

    return primary
        .map((s) => _ModuleSliver(section: s, screenKey: spec.screenKey))
        .toList(growable: false);
  }

  List<Widget> _buildAppBarActions(BuildContext context, ScreenSpec spec) {
    return spec.chrome.appBarActions
        .map((action) {
          return switch (action) {
            AppBarAction.settingsLink => IconButton(
              icon: const Icon(Icons.tune),
              onPressed: spec.chrome.settingsRoute != null
                  ? () =>
                        Routing.toScreenKey(context, spec.chrome.settingsRoute!)
                  : null,
            ),
            AppBarAction.help => const SizedBox.shrink(),
          };
        })
        .toList(growable: false);
  }

  Widget? _buildFab(ScreenSpec spec) {
    final operations = spec.chrome.fabOperations;
    if (operations.isEmpty) return null;

    final operation = operations.first;

    return switch (operation) {
      FabOperation.createTask => AddTaskFab(
        taskRepository: getIt(),
        projectRepository: getIt(),
        valueRepository: getIt(),
      ),
      FabOperation.createProject => AddProjectFab(
        projectRepository: getIt(),
        valueRepository: getIt(),
      ),
      FabOperation.createValue => AddValueFab(
        valueRepository: getIt(),
        tooltip: 'Create value',
        heroTag: 'create_value_fab',
      ),
    };
  }
}

({int doneCount, int totalCount})? _myDayTaskProgress(List<SectionVm> primary) {
  if (primary.length != 1) return null;
  final data = primary.single.data;
  if (data is! DataV2SectionResult) return null;

  final tasks = data.items.whereType<ScreenItemTask>().toList(growable: false);
  if (tasks.isEmpty) return (doneCount: 0, totalCount: 0);

  final doneCount = tasks.where((t) => t.task.completed).length;
  return (doneCount: doneCount, totalCount: tasks.length);
}

class _MyDayMyFocusCardSliver extends StatelessWidget {
  const _MyDayMyFocusCardSliver({required this.progress});

  final ({int doneCount, int totalCount})? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final doneCount = progress?.doneCount ?? 0;
    final totalCount = progress?.totalCount ?? 0;
    final showProgress = totalCount > 0;
    final fraction = showProgress
        ? (doneCount / totalCount).clamp(0.0, 1.0)
        : 0.0;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      sliver: SliverToBoxAdapter(
        child: BlocBuilder<MyDayHeaderBloc, MyDayHeaderState>(
          builder: (context, state) {
            return Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              color: scheme.surfaceContainerHighest.withOpacity(0.35),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withOpacity(0.16),
                      scheme.surface.withOpacity(0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withOpacity(
                            0.55,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.center_focus_strong,
                                  size: 18,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.focusMode.tagline,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ActionChip(
                              label: Text(
                                state.focusMode.displayName,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              backgroundColor: Colors.transparent,
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: scheme.onSurfaceVariant.withOpacity(
                                    0.35,
                                  ),
                                ),
                              ),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                context.read<MyDayHeaderBloc>().add(
                                  const MyDayHeaderFocusModeBannerTapped(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Routing.toScreenKey(
                            context,
                            AttentionBannerBloc.overflowScreenKey,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withOpacity(
                                0.35,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                BlocBuilder<
                                  AttentionBannerBloc,
                                  AttentionBannerState
                                >(
                                  builder: (context, attentionState) {
                                    final total = attentionState.totalCount;

                                    if (attentionState.isLoading) {
                                      return const LinearProgressIndicator();
                                    }

                                    final badges = <Widget>[];
                                    if (attentionState.criticalCount > 0) {
                                      badges.add(
                                        CountBadge(
                                          count: attentionState.criticalCount,
                                          color: scheme.error,
                                          label: 'Critical',
                                        ),
                                      );
                                    }
                                    if (attentionState.warningCount > 0) {
                                      badges.add(
                                        CountBadge(
                                          count: attentionState.warningCount,
                                          color: Colors.orange,
                                          label: 'Warning',
                                        ),
                                      );
                                    }
                                    if (attentionState.infoCount > 0) {
                                      badges.add(
                                        CountBadge(
                                          count: attentionState.infoCount,
                                          color: scheme.primary,
                                          label: 'Info',
                                        ),
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Icon(
                                          total == 0
                                              ? Icons.check_circle_outline
                                              : Icons.notifications_none,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child:
                                              attentionState.errorMessage !=
                                                  null
                                              ? Text(
                                                  'Attention unavailable',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                )
                                              : badges.isEmpty
                                              ? Text(
                                                  'All clear',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                )
                                              : Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: badges,
                                                ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                          ),
                        ),
                      ),
                      if (showProgress) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              "Today's progress",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  minHeight: 6,
                                  backgroundColor:
                                      scheme.surfaceContainerHighest,
                                  color: scheme.primary.withOpacity(0.70),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$doneCount/$totalCount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModuleSliver extends StatelessWidget {
  const _ModuleSliver({required this.section, required this.screenKey});

  final SectionVm section;
  final String screenKey;

  @override
  Widget build(BuildContext context) {
    final persistenceKey = '$screenKey:${section.templateId}:${section.index}';
    return SectionWidget(
      section: section,
      persistenceKey: persistenceKey,
      onEntityTap: (entity) {
        if (entity is Task) {
          Routing.toEntity(context, EntityType.task, entity.id);
        } else if (entity is Project) {
          Routing.toEntity(context, EntityType.project, entity.id);
        } else if (entity is Value) {
          Routing.toEntity(context, EntityType.value, entity.id);
        }
      },
    );
  }
}

class _MyDayEmptyStateSliver extends StatelessWidget {
  const _MyDayEmptyStateSliver({
    required this.title,
    required this.hasAttention,
    required this.onReviewInbox,
    required this.onAddTask,
  });

  final String title;
  final bool hasAttention;
  final VoidCallback? onReviewInbox;
  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateLabel = MaterialLocalizations.of(context).formatFullDate(
      DateTime.now(),
    );

    final cta = hasAttention
        ? (
            label: 'Attention',
            icon: Icons.notifications_outlined,
            onPressed: onReviewInbox,
          )
        : (
            label: 'Add task',
            icon: Icons.add,
            onPressed: onAddTask,
          );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TasklyHeader(title: title),
            const SizedBox(height: 6),
            Text(
              dateLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: scheme.surfaceContainerHighest.withOpacity(0.35),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "You're all set for today",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasAttention
                                ? 'You have items waiting for attention.'
                                : 'Add a task to shape your day.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: cta.onPressed,
                              icon: Icon(cta.icon),
                              label: Text(cta.label),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

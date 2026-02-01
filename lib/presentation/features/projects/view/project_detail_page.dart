import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_overview_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/utils/rich_text_utils.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart' show EntityType;
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProjectOverviewBloc(
            projectId: projectId,
            projectRepository: context.read<ProjectRepositoryContract>(),
            occurrenceReadService: context.read<OccurrenceReadService>(),
            sessionDayKeyService: context.read<SessionDayKeyService>(),
          ),
        ),
        BlocProvider(
          create: (context) => ProjectDetailBloc(
            projectRepository: context.read<ProjectRepositoryContract>(),
            valueRepository: context.read<ValueRepositoryContract>(),
            projectWriteService: context.read<ProjectWriteService>(),
            errorReporter: context.read<AppErrorReporter>(),
          ),
        ),
        BlocProvider(create: (_) => SelectionBloc()),
      ],
      child: _ProjectDetailView(projectId: projectId),
    );
  }
}

class _ProjectDetailView extends StatefulWidget {
  const _ProjectDetailView({required this.projectId});

  final String projectId;

  @override
  State<_ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<_ProjectDetailView> {
  _ProjectTaskSortOrder _sortOrder = _ProjectTaskSortOrder.listOrder;
  bool _showCompleted = false;

  Future<void> _openNewTaskEditor(BuildContext context) {
    final inboxId = ProjectGroupingRef.inbox().stableKey;
    final defaultProjectId = widget.projectId == inboxId
        ? null
        : widget.projectId;

    return context.read<EditorLauncher>().openTaskEditor(
      context,
      taskId: null,
      defaultProjectId: defaultProjectId,
      showDragHandle: true,
    );
  }

  Future<void> _openNewProjectEditor(BuildContext context) {
    return context.read<EditorLauncher>().openProjectEditor(
      context,
      projectId: null,
      showDragHandle: true,
    );
  }

  void _updateSortOrder(_ProjectTaskSortOrder order) {
    if (_sortOrder == order) return;
    setState(() => _sortOrder = order);
  }

  void _toggleShowCompleted(bool value) {
    if (_showCompleted == value) return;
    setState(() => _showCompleted = value);
  }

  Future<void> _showFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final tokens = TasklyTokens.of(sheetContext);
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLg,
              tokens.spaceSm,
              tokens.spaceLg,
              tokens.spaceLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter & sort',
                  style: theme.textTheme.titleLarge,
                ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  'Sort',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final order in _ProjectTaskSortOrder.values)
                  RadioListTile<_ProjectTaskSortOrder>(
                    value: order,
                    groupValue: _sortOrder,
                    title: Text(order.label),
                    onChanged: (value) {
                      if (value == null) return;
                      _updateSortOrder(value);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  'Filter',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SwitchListTile(
                  value: _showCompleted,
                  onChanged: _toggleShowCompleted,
                  title: const Text('Show completed'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inboxId = ProjectGroupingRef.inbox().stableKey;
    final isInbox = widget.projectId == inboxId;
    final appBarTitle = isInbox ? '' : 'Project details';
    final chrome = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final iconButtonStyle = IconButton.styleFrom(
      backgroundColor: scheme.surfaceContainerHighest.withValues(
        alpha: chrome.iconButtonBackgroundAlpha,
      ),
      foregroundColor: scheme.onSurface,
      shape: const CircleBorder(),
      minimumSize: Size.square(chrome.iconButtonMinSize),
      padding: chrome.iconButtonPadding,
    );

    return BlocBuilder<SelectionBloc, SelectionState>(
      builder: (context, selectionState) {
        final canPop = Navigator.of(context).canPop();
        return Scaffold(
          appBar: selectionState.isSelectionMode
              ? SelectionAppBar(
                  baseTitle: appBarTitle,
                  onExit: () {},
                )
              : AppBar(
                  centerTitle: true,
                  toolbarHeight: chrome.projectsAppBarHeight,
                  title: appBarTitle.isEmpty ? null : Text(appBarTitle),
                  leading: canPop
                      ? IconButton(
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back),
                          style: iconButtonStyle,
                          onPressed: () => Navigator.of(context).maybePop(),
                        )
                      : null,
                  actions: [
                    IconButton(
                      tooltip: 'Filter & sort',
                      icon: const Icon(Icons.tune_rounded),
                      style: iconButtonStyle,
                      onPressed: _showFilterSheet,
                    ),
                  ],
                ),
          floatingActionButton: selectionState.isSelectionMode
              ? null
              : EntityAddSpeedDial(
                  heroTag: 'add_speed_dial_project_detail',
                  onCreateTask: () => _openNewTaskEditor(context),
                  onCreateProject: () => _openNewProjectEditor(context),
                ),
          body: BlocBuilder<ProjectOverviewBloc, ProjectOverviewState>(
            builder: (context, state) {
              return switch (state) {
                ProjectOverviewLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ProjectOverviewError(:final message) => Center(
                  child: Text(message),
                ),
                ProjectOverviewLoaded(
                  :final project,
                  :final tasks,
                  :final todayDayKeyUtc,
                ) =>
                  _ProjectDetailBody(
                    project: project,
                    tasks: tasks,
                    todayDayKeyUtc: todayDayKeyUtc,
                    selectionState: selectionState,
                    sortOrder: _sortOrder,
                    showCompleted: _showCompleted,
                  ),
              };
            },
          ),
        );
      },
    );
  }
}

class _ProjectDetailBody extends StatelessWidget {
  const _ProjectDetailBody({
    required this.project,
    required this.tasks,
    required this.todayDayKeyUtc,
    required this.selectionState,
    required this.sortOrder,
    required this.showCompleted,
  });

  final Project project;
  final List<Task> tasks;
  final DateTime todayDayKeyUtc;
  final SelectionState selectionState;
  final _ProjectTaskSortOrder sortOrder;
  final bool showCompleted;

  @override
  Widget build(BuildContext context) {
    final isInbox = project.id == ProjectGroupingRef.inbox().stableKey;
    final dueSoonCount = _countDueSoon(tasks, todayDayKeyUtc);

    final completed = tasks
        .where((task) => task.occurrence?.isCompleted ?? task.completed)
        .toList();
    final open = tasks
        .where((task) => !(task.occurrence?.isCompleted ?? task.completed))
        .toList();

    final remainingOpen = open;
    final orderedOpen = _sortTasks(remainingOpen, sortOrder);
    final orderedCompleted = showCompleted
        ? _sortTasks(completed, sortOrder)
        : const <Task>[];

    final headerData = buildProjectRowData(
      context,
      project: project,
      taskCount: tasks.length,
      completedTaskCount: completed.length,
      dueSoonCount: dueSoonCount,
    );
    void openEdit() {
      context.read<EditorLauncher>().openProjectEditor(
        context,
        projectId: project.id,
        showDragHandle: true,
      );
    }

    final selection = context.read<SelectionBloc>();
    final visibleTasks = [...orderedOpen, ...orderedCompleted];
    _registerVisibleTasks(selection, visibleTasks);

    final normalizedDescription = serializeParchmentDocument(
      parseParchmentDocument(project.description),
    );

    void updateDescription(String nextDescription) {
      if (normalizedDescription == nextDescription || isInbox) return;

      final valueIds = project.values.isNotEmpty
          ? project.values.map((value) => value.id).toList(growable: false)
          : project.primaryValueId != null
          ? <String>[project.primaryValueId!]
          : const <String>[];

      context.read<ProjectDetailBloc>().add(
        ProjectDetailEvent.update(
          command: UpdateProjectCommand(
            id: project.id,
            name: project.name,
            completed: project.completed,
            description: nextDescription,
            startDate: project.startDate,
            deadlineDate: project.deadlineDate,
            priority: project.priority,
            repeatIcalRrule: project.repeatIcalRrule,
            repeatFromCompletion: project.repeatFromCompletion,
            seriesEnded: project.seriesEnded,
            valueIds: valueIds,
          ),
        ),
      );
    }

    final rows = <TasklyRowSpec>[
      TasklyRowSpec.header(
        key: 'project-detail-open-header',
        title: 'Tasks',
        trailingLabel: '${orderedOpen.length} remaining',
      ),
      ...orderedOpen.map(
        (task) => _buildProjectTaskRow(context, task, selectionState),
      ),
      if (orderedCompleted.isNotEmpty) ...[
        TasklyRowSpec.header(
          key: 'project-detail-completed-header',
          title: 'Completed',
        ),
        ...orderedCompleted.map(
          (task) => _buildProjectTaskRow(context, task, selectionState),
        ),
      ],
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceSm,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXl,
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProjectDetailHeader(
              data: headerData,
              isInbox: isInbox,
              onEditRequested: isInbox ? null : openEdit,
            ),
            if (!isInbox) ...[
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              _ProjectNotesEditor(
                rawNotes: normalizedDescription,
                hintText: context.l10n.projectFormDescriptionHint,
                onNotesChanged: updateDescription,
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
            ],
            TasklyFeedRenderer.buildSection(
              TasklySectionSpec.standardList(id: 'project-detail', rows: rows),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProjectDetailHeader extends StatelessWidget {
  const _ProjectDetailHeader({
    required this.data,
    required this.isInbox,
    required this.onEditRequested,
  });

  final TasklyProjectRowData data;
  final bool isInbox;
  final VoidCallback? onEditRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final titleStyle =
        theme.textTheme.headlineSmall ?? theme.textTheme.titleLarge;
    final metaStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final primaryValue = data.leadingChip;
    final totalCount = data.taskCount;
    final completedCount = data.completedTaskCount;

    final metaChildren = <Widget>[];

    if (isInbox) {
      metaChildren.add(
        MetaIconLabel(
          icon: Icons.inbox_outlined,
          label: 'Inbox',
          color: scheme.onSurfaceVariant,
          textStyle: metaStyle,
        ),
      );
    }

    if (primaryValue != null) {
      metaChildren.add(
        _ValueInlineLabel(
          data: primaryValue,
          maxLabelChars: 18,
          textColor: scheme.onSurfaceVariant,
        ),
      );
    }

    if (totalCount != null) {
      final showCompletionRatio = !isInbox && completedCount != null;
      metaChildren.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showCompletionRatio
                  ? Icons.check_circle_rounded
                  : Icons.inbox_outlined,
              size: 14,
              color: showCompletionRatio
                  ? scheme.secondary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            SizedBox(width: tokens.spaceXs),
            Text(
              showCompletionRatio
                  ? '$completedCount/$totalCount tasks'
                  : '$totalCount tasks',
              style: metaStyle,
            ),
          ],
        ),
      );
    }

    final dueSoon = data.dueSoonCount ?? 0;
    final dueLabel = data.meta.deadlineDateLabel?.trim();
    final showDue = (dueLabel != null && dueLabel.isNotEmpty) || dueSoon > 0;
    if (showDue) {
      final dueColor = (data.meta.isOverdue || data.meta.isDueToday)
          ? scheme.error
          : scheme.onSurfaceVariant;
      metaChildren.add(
        MetaIconLabel(
          icon: Icons.flag_rounded,
          label: (dueLabel != null && dueLabel.isNotEmpty)
              ? dueLabel
              : '$dueSoon due soon',
          color: dueColor,
          textStyle: metaStyle,
        ),
      );
    }

    if (data.meta.priority != null) {
      metaChildren.add(PriorityPill(priority: data.meta.priority!));
    }

    final canEdit = onEditRequested != null;
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              decoration: data.completed ? TextDecoration.lineThrough : null,
              decorationColor: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        if (canEdit)
          IconButton(
            tooltip: 'Edit project',
            onPressed: onEditRequested,
            icon: const Icon(Icons.edit_rounded),
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
              backgroundColor: scheme.surfaceContainerHighest.withValues(
                alpha: tokens.iconButtonBackgroundAlpha,
              ),
              minimumSize: Size.square(tokens.minTapTargetSize),
              padding: EdgeInsets.all(tokens.spaceXs2),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canEdit)
          InkWell(
            onTap: onEditRequested,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            child: Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceXs2),
              child: titleRow,
            ),
          )
        else
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceXs2),
            child: titleRow,
          ),
        if (metaChildren.isNotEmpty)
          Wrap(
            spacing: tokens.spaceSm2,
            runSpacing: tokens.spaceXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: metaChildren,
          ),
      ],
    );
  }
}

class _ProjectNotesEditor extends StatefulWidget {
  const _ProjectNotesEditor({
    required this.rawNotes,
    required this.hintText,
    required this.onNotesChanged,
  });

  final String rawNotes;
  final String hintText;
  final ValueChanged<String> onNotesChanged;

  @override
  State<_ProjectNotesEditor> createState() => _ProjectNotesEditorState();
}

class _ProjectNotesEditorState extends State<_ProjectNotesEditor> {
  static const _debounceDuration = Duration(milliseconds: 450);

  late FleatherController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isEmpty = true;
  bool _syncing = false;
  String? _lastSerialized;
  String? _lastCommitted;
  String? _pendingSerialized;

  @override
  void initState() {
    super.initState();
    _controller = FleatherController(
      document: parseParchmentDocument(widget.rawNotes),
    );
    _lastSerialized = serializeParchmentDocument(_controller.document);
    _lastCommitted = _lastSerialized;
    _isEmpty = _controller.document.toPlainText().trim().isEmpty;
    _controller.addListener(_handleDocumentChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _ProjectNotesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawNotes != widget.rawNotes) {
      _replaceDocument(widget.rawNotes);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleDocumentChanged);
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleDocumentChanged() {
    if (_syncing) return;
    final serialized = serializeParchmentDocument(_controller.document);
    if (serialized != _lastSerialized) {
      _lastSerialized = serialized;
      _pendingSerialized = serialized;
      _scheduleCommit();
    }

    final emptyNow = _controller.document.toPlainText().trim().isEmpty;
    if (emptyNow != _isEmpty && mounted) {
      setState(() => _isEmpty = emptyNow);
    }
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _commitPending();
    }
  }

  void _scheduleCommit() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _commitPending);
  }

  void _commitPending() {
    _debounceTimer?.cancel();
    final next = _pendingSerialized;
    if (next == null || next == _lastCommitted) return;
    _lastCommitted = next;
    _pendingSerialized = null;
    widget.onNotesChanged(next);
  }

  void _replaceDocument(String rawNotes) {
    if (rawNotes == _lastSerialized) return;

    _syncing = true;
    _debounceTimer?.cancel();
    _controller.removeListener(_handleDocumentChanged);
    _controller.dispose();
    _controller = FleatherController(
      document: parseParchmentDocument(rawNotes),
    );
    _lastSerialized = serializeParchmentDocument(_controller.document);
    _lastCommitted = _lastSerialized;
    _pendingSerialized = null;
    _isEmpty = _controller.document.toPlainText().trim().isEmpty;
    _controller.addListener(_handleDocumentChanged);
    _syncing = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final editorHeight = isCompact ? 160.0 : 200.0;
    final contentPadding = EdgeInsets.all(tokens.spaceSm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FleatherToolbar.basic(
          controller: _controller,
          hideStrikeThrough: true,
          hideBackgroundColor: true,
          hideInlineCode: true,
          hideIndentation: true,
          hideCodeBlock: true,
          hideHorizontalRule: true,
          hideDirection: true,
          hideAlignment: true,
        ),
        SizedBox(height: tokens.spaceSm),
        Container(
          height: editorHeight,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Stack(
            children: [
              FleatherEditor(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _scrollController,
                padding: contentPadding,
              ),
              if (_isEmpty)
                IgnorePointer(
                  child: Padding(
                    padding: contentPadding,
                    child: Text(
                      widget.hintText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValueInlineLabel extends StatelessWidget {
  const _ValueInlineLabel({
    required this.data,
    required this.maxLabelChars,
    required this.textColor,
  });

  final ValueChipData data;
  final int maxLabelChars;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final label = _formatLabel(data.label, maxLabelChars);
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data.icon, size: tokens.spaceMd2, color: data.color),
        SizedBox(width: tokens.spaceXxs2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
              .copyWith(color: textColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

String? _formatLabel(String label, int maxChars) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.length <= maxChars) return trimmed;
  if (maxChars <= 3) return trimmed.substring(0, maxChars);
  final keep = maxChars - 3;
  return '${trimmed.substring(0, keep)}...';
}

TasklyRowSpec _buildProjectTaskRow(
  BuildContext context,
  Task task,
  SelectionState selectionState, {
  List<TasklyBadgeData> badges = const [],
  VoidCallback? onTapOverride,
  VoidCallback? onLongPressOverride,
}) {
  final selection = context.read<SelectionBloc>();
  final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
  final data = buildTaskRowData(
    context,
    task: task,
    tileCapabilities: tileCapabilities,
  );

  final key = SelectionKey(
    entityType: EntityType.task,
    entityId: task.id,
  );
  final isSelected = selectionState.selected.contains(key);

  final rowData = TasklyTaskRowData(
    id: data.id,
    title: data.title,
    completed: data.completed,
    meta: data.meta,
    leadingChip: data.leadingChip,
    secondaryChips: data.secondaryChips,
    badges: badges,
    deemphasized: data.deemphasized,
    checkboxSemanticLabel: data.checkboxSemanticLabel,
    labels: data.labels,
    pinned: false,
  );

  final style = selectionState.isSelectionMode
      ? TasklyTaskRowStyle.bulkSelection(selected: isSelected)
      : const TasklyTaskRowStyle.standard();

  return TasklyRowSpec.task(
    key: 'project-detail-task-${task.id}',
    data: rowData,
    style: style,
    actions: TasklyTaskRowActions(
      onTap: () {
        if (selection.shouldInterceptTapAsSelection()) {
          selection.handleEntityTap(key);
          return;
        }
        if (onTapOverride != null) {
          onTapOverride();
        } else {
          buildTaskOpenEditorHandler(context, task: task)();
        }
      },
      onLongPress: () {
        if (onLongPressOverride != null) {
          onLongPressOverride();
        } else {
          selection.enterSelectionMode(initialSelection: key);
        }
      },
      onToggleSelected: selectionState.isSelectionMode
          ? () => selection.handleEntityTap(key)
          : null,
      onToggleCompletion: buildTaskToggleCompletionHandler(
        context,
        task: task,
        tileCapabilities: tileCapabilities,
      ),
    ),
  );
}

void _registerVisibleTasks(
  SelectionBloc selection,
  List<Task> tasks,
) {
  selection.updateVisibleEntities(
    tasks
        .map(
          (task) => SelectionEntityMeta(
            key: SelectionKey(
              entityType: EntityType.task,
              entityId: task.id,
            ),
            displayName: task.name,
            canDelete: true,
            completed: task.completed,
            canCompleteSeries: task.isRepeating && !task.seriesEnded,
          ),
        )
        .toList(growable: false),
  );
}

int _countDueSoon(
  List<Task> tasks,
  DateTime todayDayKeyUtc,
) {
  const dueWindowDays = 7;
  final today = DateTime.utc(
    todayDayKeyUtc.year,
    todayDayKeyUtc.month,
    todayDayKeyUtc.day,
  );
  final dueLimit = today.add(
    Duration(days: dueWindowDays.clamp(1, 30) - 1),
  );

  int count = 0;
  for (final task in tasks) {
    if (task.occurrence?.isCompleted ?? task.completed) continue;
    final deadline = task.occurrence?.deadline ?? task.deadlineDate;
    if (deadline == null) continue;
    final deadlineDay = DateTime.utc(
      deadline.year,
      deadline.month,
      deadline.day,
    );
    if (!deadlineDay.isBefore(today) && !deadlineDay.isAfter(dueLimit)) {
      count += 1;
    }
  }
  return count;
}

enum _ProjectTaskSortOrder {
  listOrder,
  recentlyUpdated,
  alphabetical,
  priority,
  dueDate,
}

extension _ProjectTaskSortOrderLabels on _ProjectTaskSortOrder {
  String get label {
    return switch (this) {
      _ProjectTaskSortOrder.listOrder => 'Default',
      _ProjectTaskSortOrder.recentlyUpdated => 'Recently updated',
      _ProjectTaskSortOrder.alphabetical => 'A–Z',
      _ProjectTaskSortOrder.priority => 'Priority',
      _ProjectTaskSortOrder.dueDate => 'Due date',
    };
  }
}

List<Task> _sortTasks(List<Task> tasks, _ProjectTaskSortOrder order) {
  if (order == _ProjectTaskSortOrder.listOrder) {
    return tasks.toList(growable: false);
  }

  int byName(Task a, Task b) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int byUpdated(Task a, Task b) {
    final byUpdated = b.updatedAt.compareTo(a.updatedAt);
    if (byUpdated != 0) return byUpdated;
    return byName(a, b);
  }

  int byPriority(Task a, Task b) {
    final aPriority = a.priority ?? 999;
    final bPriority = b.priority ?? 999;
    final byPriority = aPriority.compareTo(bPriority);
    if (byPriority != 0) return byPriority;
    return byName(a, b);
  }

  int byDueDate(Task a, Task b) {
    final aDate = a.occurrence?.deadline ?? a.deadlineDate;
    final bDate = b.occurrence?.deadline ?? b.deadlineDate;
    if (aDate != null && bDate != null) {
      final byDate = aDate.compareTo(bDate);
      if (byDate != 0) return byDate;
    } else if (aDate != null || bDate != null) {
      return aDate != null ? -1 : 1;
    }
    return byName(a, b);
  }

  final sorted = tasks.toList(growable: false);
  sorted.sort(
    switch (order) {
      _ProjectTaskSortOrder.recentlyUpdated => byUpdated,
      _ProjectTaskSortOrder.alphabetical => byName,
      _ProjectTaskSortOrder.priority => byPriority,
      _ProjectTaskSortOrder.dueDate => byDueDate,
      _ProjectTaskSortOrder.listOrder => byName,
    },
  );
  return sorted;
}

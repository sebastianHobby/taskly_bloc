import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_library_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/widgets/taskly_bottom_sheet.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_icons.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalManageFactorsPage extends StatefulWidget {
  const JournalManageFactorsPage({super.key});

  @override
  State<JournalManageFactorsPage> createState() =>
      _JournalManageFactorsPageState();
}

class _JournalManageFactorsPageState extends State<JournalManageFactorsPage> {
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalManageLibraryBloc>(
      create: (context) => JournalManageLibraryBloc(
        repository: context.read<JournalRepositoryContract>(),
        errorReporter: context.read<AppErrorReporter>(),
        nowUtc: context.read<NowService>().nowUtc,
      ),
      child: DefaultTabController(
        length: 2,
        child:
            BlocConsumer<JournalManageLibraryBloc, JournalManageLibraryState>(
              listenWhen: (previous, current) {
                if (current is! JournalManageLibraryLoaded) return false;
                if (previous is! JournalManageLibraryLoaded) return true;
                return previous.status.runtimeType !=
                    current.status.runtimeType;
              },
              listener: (context, state) {
                if (state is! JournalManageLibraryLoaded) return;
                if (state.status case JournalManageLibraryActionError(
                  :final message,
                )) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              },
              builder: (context, state) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(context.l10n.journalManageTrackersTitle),
                    bottom: TabBar(
                      tabs: [
                        Tab(text: context.l10n.trackersTitle),
                        Tab(text: context.l10n.groupsTitle),
                      ],
                    ),
                  ),
                  body: switch (state) {
                    JournalManageLibraryLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    JournalManageLibraryError(:final message) => Center(
                      child: Padding(
                        padding: EdgeInsets.all(
                          TasklyTokens.of(context).spaceLg,
                        ),
                        child: Text(message),
                      ),
                    ),
                    JournalManageLibraryLoaded() => TabBarView(
                      children: [
                        _TrackersTab(
                          state: state,
                          showInactive: _showInactive,
                          onShowInactiveChanged: (value) {
                            setState(() {
                              _showInactive = value;
                            });
                          },
                        ),
                        _GroupsTab(state: state),
                      ],
                    ),
                  },
                );
              },
            ),
      ),
    );
  }
}

class _TrackersTab extends StatelessWidget {
  const _TrackersTab({
    required this.state,
    required this.showInactive,
    required this.onShowInactiveChanged,
  });

  final JournalManageLibraryLoaded state;
  final bool showInactive;
  final ValueChanged<bool> onShowInactiveChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final visibleTrackers = state.trackers
        .where((tracker) => showInactive || tracker.isActive)
        .toList(growable: false);
    final groupedTrackers = <String?, List<TrackerDefinition>>{};
    for (final tracker in visibleTrackers) {
      groupedTrackers.putIfAbsent(tracker.groupId, () => <TrackerDefinition>[]);
      groupedTrackers[tracker.groupId]!.add(tracker);
    }

    return ListView(
      padding: EdgeInsets.all(tokens.spaceLg),
      children: [
        FilledButton.icon(
          onPressed: () => Routing.toJournalTrackerWizard(context),
          icon: const Icon(Icons.add),
          label: Text(context.l10n.journalNewTrackerTitle),
        ),
        SizedBox(height: tokens.spaceMd),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.showInactiveLabel),
          value: showInactive,
          onChanged: onShowInactiveChanged,
        ),
        SizedBox(height: tokens.spaceSm),
        if (visibleTrackers.isEmpty)
          _SectionCard(
            title: context.l10n.trackersTitle,
            child: Text(context.l10n.journalNoEntryTrackers),
          )
        else ...[
          for (final group in state.groups)
            if ((groupedTrackers[group.id] ?? const <TrackerDefinition>[])
                .isNotEmpty) ...[
              _TrackerSection(
                title: group.name,
                trackers: groupedTrackers[group.id]!,
                allGroups: state.groups,
              ),
              SizedBox(height: tokens.spaceMd),
            ],
          if ((groupedTrackers[null] ?? const <TrackerDefinition>[]).isNotEmpty)
            _TrackerSection(
              title: context.l10n.noneLabel,
              trackers: groupedTrackers[null]!,
              allGroups: state.groups,
            ),
        ],
      ],
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab({required this.state});

  final JournalManageLibraryLoaded state;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);

    return ListView(
      padding: EdgeInsets.all(tokens.spaceLg),
      children: [
        FilledButton.icon(
          onPressed: () => _promptForGroupName(context),
          icon: const Icon(Icons.create_new_folder_outlined),
          label: Text(context.l10n.journalNewGroupTitle),
        ),
        SizedBox(height: tokens.spaceMd),
        if (state.groups.isEmpty)
          _SectionCard(
            title: context.l10n.groupsTitle,
            child: Text(context.l10n.noValuesFound),
          )
        else
          _SectionCard(
            title: context.l10n.groupsTitle,
            child: Column(
              children: [
                for (var index = 0; index < state.groups.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _GroupRow(
                    group: state.groups[index],
                    canMoveUp: index > 0,
                    canMoveDown: index < state.groups.length - 1,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TrackerSection extends StatelessWidget {
  const _TrackerSection({
    required this.title,
    required this.trackers,
    required this.allGroups,
  });

  final String title;
  final List<TrackerDefinition> trackers;
  final List<TrackerGroup> allGroups;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: Column(
        children: [
          for (var index = 0; index < trackers.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _TrackerRow(
              tracker: trackers[index],
              allGroups: allGroups,
              canMoveUp: index > 0,
              canMoveDown: index < trackers.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackerRow extends StatelessWidget {
  const _TrackerRow({
    required this.tracker,
    required this.allGroups,
    required this.canMoveUp,
    required this.canMoveDown,
  });

  final TrackerDefinition tracker;
  final List<TrackerGroup> allGroups;
  final bool canMoveUp;
  final bool canMoveDown;

  bool get _isSystem => tracker.systemKey?.trim().isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      tracker.scope,
      tracker.valueType,
      if (!tracker.isActive) 'inactive',
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        foregroundColor: theme.colorScheme.onSecondaryContainer,
        child: Icon(trackerIconData(tracker)),
      ),
      title: Text(tracker.name),
      subtitle: Text(subtitle),
      trailing: PopupMenuButton<_TrackerAction>(
        tooltip: MaterialLocalizations.of(context).showMenuTooltip,
        icon: const Icon(Icons.more_horiz),
        onSelected: (action) => _handleTrackerAction(context, action),
        itemBuilder: (context) => [
          if (!_isSystem)
            PopupMenuItem(
              value: _TrackerAction.rename,
              child: Text(context.l10n.renameLabel),
            ),
          PopupMenuItem(
            value: _TrackerAction.icon,
            child: Text(context.l10n.valueFormIconLabel),
          ),
          PopupMenuItem(
            value: _TrackerAction.group,
            child: Text(context.l10n.groupLabel),
          ),
          if (canMoveUp)
            PopupMenuItem(
              value: _TrackerAction.moveUp,
              child: Text(context.l10n.moveUpLabel),
            ),
          if (canMoveDown)
            PopupMenuItem(
              value: _TrackerAction.moveDown,
              child: Text(context.l10n.moveDownLabel),
            ),
          PopupMenuItem(
            value: tracker.isActive
                ? _TrackerAction.deactivate
                : _TrackerAction.activate,
            child: Text(
              tracker.isActive
                  ? context.l10n.deactivateLabel
                  : context.l10n.activateLabel,
            ),
          ),
          if (!_isSystem)
            PopupMenuItem(
              value: _TrackerAction.delete,
              child: Text(context.l10n.deleteLabel),
            ),
        ],
      ),
    );
  }

  Future<void> _handleTrackerAction(
    BuildContext context,
    _TrackerAction action,
  ) async {
    final bloc = context.read<JournalManageLibraryBloc>();
    switch (action) {
      case _TrackerAction.rename:
        final renamed = await _showNameSheet(
          context,
          title: context.l10n.renameLabel,
          initialValue: tracker.name,
          actionLabel: context.l10n.saveLabel,
        );
        if (renamed == null) return;
        await bloc.renameTracker(def: tracker, name: renamed);
      case _TrackerAction.icon:
        final iconName = await _showIconPicker(context, tracker);
        if (iconName == null) return;
        await bloc.setTrackerIcon(def: tracker, iconName: iconName);
      case _TrackerAction.group:
        final groupId = await _showGroupPicker(
          context,
          groups: allGroups,
          currentGroupId: tracker.groupId,
        );
        if (!context.mounted || groupId == _SelectionDismissed.token) return;
        await bloc.moveTrackerToGroup(
          def: tracker,
          groupId: groupId?.isEmpty == true ? null : groupId,
        );
      case _TrackerAction.moveUp:
        await bloc.reorderTrackersWithinGroup(
          trackerId: tracker.id,
          groupId: tracker.groupId,
          direction: -1,
        );
      case _TrackerAction.moveDown:
        await bloc.reorderTrackersWithinGroup(
          trackerId: tracker.id,
          groupId: tracker.groupId,
          direction: 1,
        );
      case _TrackerAction.deactivate:
        await bloc.setTrackerActive(def: tracker, isActive: false);
      case _TrackerAction.activate:
        await bloc.setTrackerActive(def: tracker, isActive: true);
      case _TrackerAction.delete:
        final shouldDelete = await _confirmDeleteTracker(context, tracker);
        if (!context.mounted || shouldDelete != true) return;
        await bloc.deleteTracker(def: tracker);
    }
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.canMoveUp,
    required this.canMoveDown,
  });

  final TrackerGroup group;
  final bool canMoveUp;
  final bool canMoveDown;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.folder_outlined),
      title: Text(group.name),
      trailing: PopupMenuButton<_GroupAction>(
        tooltip: MaterialLocalizations.of(context).showMenuTooltip,
        icon: const Icon(Icons.more_horiz),
        onSelected: (action) => _handleGroupAction(context, action),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _GroupAction.rename,
            child: Text(context.l10n.renameLabel),
          ),
          if (canMoveUp)
            PopupMenuItem(
              value: _GroupAction.moveUp,
              child: Text(context.l10n.moveUpLabel),
            ),
          if (canMoveDown)
            PopupMenuItem(
              value: _GroupAction.moveDown,
              child: Text(context.l10n.moveDownLabel),
            ),
          PopupMenuItem(
            value: _GroupAction.delete,
            child: Text(context.l10n.deleteLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGroupAction(
    BuildContext context,
    _GroupAction action,
  ) async {
    final bloc = context.read<JournalManageLibraryBloc>();
    switch (action) {
      case _GroupAction.rename:
        final renamed = await _showNameSheet(
          context,
          title: context.l10n.renameLabel,
          initialValue: group.name,
          actionLabel: context.l10n.saveLabel,
        );
        if (renamed == null) return;
        await bloc.renameGroup(group: group, name: renamed);
      case _GroupAction.moveUp:
        await bloc.reorderGroups(groupId: group.id, direction: -1);
      case _GroupAction.moveDown:
        await bloc.reorderGroups(groupId: group.id, direction: 1);
      case _GroupAction.delete:
        final confirmed = await _confirmDeleteGroup(context, group);
        if (!context.mounted || confirmed != true) return;
        await bloc.deleteGroup(group);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceSm),
          child,
        ],
      ),
    );
  }
}

Future<void> _promptForGroupName(BuildContext context) async {
  final name = await _showNameSheet(
    context,
    title: context.l10n.journalNewGroupTitle,
    actionLabel: context.l10n.createLabel,
  );
  if (!context.mounted || name == null) return;
  await context.read<JournalManageLibraryBloc>().createGroup(name);
}

Future<String?> _showNameSheet(
  BuildContext context, {
  required String title,
  required String actionLabel,
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  final tokens = TasklyTokens.of(context);
  final value = await showModalBottomSheet<String>(
    context: context,
    sheetAnimationStyle: tasklyBottomSheetAnimationStyle(context),
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        MediaQuery.viewInsetsOf(sheetContext).bottom + tokens.spaceLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(sheetContext).textTheme.titleLarge,
          ),
          SizedBox(height: tokens.spaceMd),
          TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(sheetContext).pop(value),
          ),
          SizedBox(height: tokens.spaceMd),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(controller.text),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

Future<String?> _showIconPicker(
  BuildContext context,
  TrackerDefinition tracker,
) async {
  final tokens = TasklyTokens.of(context);
  return showModalBottomSheet<String>(
    context: context,
    sheetAnimationStyle: tasklyBottomSheetAnimationStyle(context),
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      child: TasklyFormIconSearchPicker(
        icons: tasklySymbolIcons,
        selectedIconName: effectiveTrackerIconName(tracker),
        searchHintText: sheetContext.l10n.valueFormIconSearchHint,
        noIconsFoundLabel: sheetContext.l10n.valueFormIconNoResults,
        tooltipBuilder: formatIconLabel,
        onSelected: (iconName) => Navigator.of(sheetContext).pop(iconName),
      ),
    ),
  );
}

Future<String?> _showGroupPicker(
  BuildContext context, {
  required List<TrackerGroup> groups,
  required String? currentGroupId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    sheetAnimationStyle: tasklyBottomSheetAnimationStyle(context),
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(sheetContext.l10n.noneLabel),
            trailing: currentGroupId == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(sheetContext).pop(''),
          ),
          for (final group in groups)
            ListTile(
              title: Text(group.name),
              trailing: currentGroupId == group.id
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(group.id),
            ),
        ],
      ),
    ),
  ).then((value) => value ?? _SelectionDismissed.token);
}

Future<bool?> _confirmDeleteGroup(
  BuildContext context,
  TrackerGroup group,
) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.deleteLabel),
      content: Text(context.l10n.deleteConfirmationQuestion(group.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(context.l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(context.l10n.deleteLabel),
        ),
      ],
    ),
  );
}

Future<bool?> _confirmDeleteTracker(
  BuildContext context,
  TrackerDefinition tracker,
) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.journalDeleteTrackerTitle),
      content: Text(context.l10n.journalDeleteTrackerMessage(tracker.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(context.l10n.cancelLabel),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop(false);
            await context.read<JournalManageLibraryBloc>().setTrackerActive(
              def: tracker,
              isActive: false,
            );
          },
          child: Text(context.l10n.journalArchiveInsteadLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(context.l10n.deleteLabel),
        ),
      ],
    ),
  );
}

enum _TrackerAction {
  rename,
  icon,
  group,
  moveUp,
  moveDown,
  deactivate,
  activate,
  delete,
}

enum _GroupAction {
  rename,
  moveUp,
  moveDown,
  delete,
}

abstract final class _SelectionDismissed {
  static const token = '__dismissed__';
}

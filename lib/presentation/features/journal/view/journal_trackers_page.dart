import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_library_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalTrackersPage extends StatelessWidget {
  const JournalTrackersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalManageLibraryBloc>(
      create: (context) => JournalManageLibraryBloc(
        repository: context.read<JournalRepositoryContract>(),
        errorReporter: context.read<AppErrorReporter>(),
        nowUtc: context.read<NowService>().nowUtc,
      ),
      child: BlocConsumer<JournalManageLibraryBloc, JournalManageLibraryState>(
        listenWhen: (prev, next) {
          final p = prev is JournalManageLibraryLoaded ? prev.status : null;
          final n = next is JournalManageLibraryLoaded ? next.status : null;
          return p?.runtimeType != n?.runtimeType;
        },
        listener: (context, state) {
          if (state is! JournalManageLibraryLoaded) return;
          final status = state.status;
          if (status is JournalManageLibraryActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(status.message)),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            JournalManageLibraryLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            JournalManageLibraryError(:final message) => Scaffold(
              body: Center(child: Text(message)),
            ),
            JournalManageLibraryLoaded(
              :final groups,
              :final trackers,
              :final status,
            ) =>
              _ManageLibraryView(
                groups: groups,
                trackers: trackers,
                status: status,
              ),
          };
        },
      ),
    );
  }
}

class _ManageLibraryView extends StatelessWidget {
  const _ManageLibraryView({
    required this.groups,
    required this.trackers,
    required this.status,
  });

  final List<TrackerGroup> groups;
  final List<TrackerDefinition> trackers;
  final JournalManageLibraryStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = status is JournalManageLibrarySaving;
    final l10n = context.l10n;

    List<TrackerGroup?> groupOptions() {
      return <TrackerGroup?>[null, ...groups];
    }

    String groupLabel(TrackerGroup? group) =>
        group?.name ?? l10n.journalGroupUngrouped;

    List<TrackerDefinition> trackersForGroup(String? groupId) {
      final key = groupId ?? '';
      return trackers
          .where((d) => (d.groupId ?? '') == key)
          .toList(growable: false)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    Future<String?> showCreateGroupDialog() async {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => _JournalNameDialog(
          title: l10n.journalNewGroupTitle,
          initialValue: '',
          labelText: l10n.nameLabel,
          hintText: l10n.journalGroupNameHint,
          cancelLabel: l10n.cancelLabel,
          submitLabel: l10n.createLabel,
        ),
      );

      final name = (result ?? '').trim();
      if (name.isEmpty) return null;
      return name;
    }

    Future<String?> showRenameDialog(String currentName) async {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => _JournalNameDialog(
          title: l10n.journalRenameGroupTitle,
          initialValue: currentName,
          labelText: l10n.nameLabel,
          cancelLabel: l10n.cancelLabel,
          submitLabel: l10n.saveLabel,
        ),
      );

      final name = (result ?? '').trim();
      if (name.isEmpty) return null;
      return name;
    }

    Future<String?> showRenameTrackerBottomSheet(String currentName) async {
      return showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => _JournalNameBottomSheet(
          title: l10n.journalRenameTrackerTitle,
          initialValue: currentName,
          labelText: l10n.nameLabel,
          cancelLabel: l10n.cancelLabel,
          submitLabel: l10n.saveLabel,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journalManageTrackersTitle),
        actions: [
          IconButton(
            tooltip: l10n.journalNewGroupTooltip,
            onPressed: isSaving
                ? null
                : () async {
                    final name = await showCreateGroupDialog();
                    if (name == null) return;
                    if (!context.mounted) return;
                    await context.read<JournalManageLibraryBloc>().createGroup(
                      name,
                    );
                  },
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          IconButton(
            tooltip: l10n.journalNewTrackerTooltip,
            onPressed: isSaving
                ? null
                : () => Routing.toJournalTrackerWizard(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          TasklyTokens.of(context).spaceMd,
          TasklyTokens.of(context).spaceMd,
          TasklyTokens.of(context).spaceMd,
          TasklyTokens.of(context).spaceXl,
        ),
        children: [
          Text(l10n.groupsTitle, style: theme.textTheme.titleMedium),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          Card(
            child: Column(
              children: [
                if (groups.isEmpty)
                  ListTile(
                    title: Text(l10n.journalNoGroupsYet),
                  )
                else
                  for (final g in groups)
                    ListTile(
                      title: Text(g.name),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: l10n.moveUpLabel,
                            onPressed: isSaving
                                ? null
                                : () => context
                                      .read<JournalManageLibraryBloc>()
                                      .reorderGroups(
                                        groupId: g.id,
                                        direction: -1,
                                      ),
                            icon: const Icon(Icons.arrow_upward),
                          ),
                          IconButton(
                            tooltip: l10n.moveDownLabel,
                            onPressed: isSaving
                                ? null
                                : () => context
                                      .read<JournalManageLibraryBloc>()
                                      .reorderGroups(
                                        groupId: g.id,
                                        direction: 1,
                                      ),
                            icon: const Icon(Icons.arrow_downward),
                          ),
                          IconButton(
                            tooltip: l10n.renameLabel,
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final name = await showRenameDialog(g.name);
                                    if (name == null) return;
                                    if (!context.mounted) return;
                                    await context
                                        .read<JournalManageLibraryBloc>()
                                        .renameGroup(group: g, name: name);
                                  },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: l10n.deleteLabel,
                            onPressed: isSaving
                                ? null
                                : () => context
                                      .read<JournalManageLibraryBloc>()
                                      .deleteGroup(g),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          Text(l10n.trackersTitle, style: theme.textTheme.titleMedium),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          for (final group in groupOptions())
            Builder(
              builder: (context) {
                final groupId = group?.id;
                final inGroup = trackersForGroup(groupId);
                if (inGroup.isEmpty) return SizedBox.shrink();

                return Card(
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(groupLabel(group)),
                    children: [
                      for (final d in inGroup)
                        Builder(
                          builder: (context) {
                            final selectedGroup = groupOptions().firstWhere(
                              (g) => (g?.id ?? '') == (d.groupId ?? ''),
                              orElse: () => null,
                            );

                            return Column(
                              children: [
                                ListTile(
                                  title: Text(d.name),
                                  subtitle: Text(
                                    l10n.journalTrackerTypeScopeLabel(
                                      d.valueType,
                                      d.scope,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: d.isActive,
                                        onChanged: isSaving
                                            ? null
                                            : (v) => context
                                                  .read<
                                                    JournalManageLibraryBloc
                                                  >()
                                                  .setTrackerActive(
                                                    def: d,
                                                    isActive: v,
                                                  ),
                                      ),
                                      IconButton(
                                        tooltip: l10n.renameLabel,
                                        onPressed: isSaving
                                            ? null
                                            : () async {
                                                final name =
                                                    await showRenameTrackerBottomSheet(
                                                      d.name,
                                                    );
                                                if (name == null) return;
                                                if (!context.mounted) return;
                                                await context
                                                    .read<
                                                      JournalManageLibraryBloc
                                                    >()
                                                    .renameTracker(
                                                      def: d,
                                                      name: name,
                                                    );
                                              },
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child:
                                            DropdownButtonFormField<
                                              TrackerGroup?
                                            >(
                                              value: selectedGroup,
                                              decoration: InputDecoration(
                                                labelText: l10n.groupLabel,
                                              ),
                                              items: [
                                                for (final g in groupOptions())
                                                  DropdownMenuItem<
                                                    TrackerGroup?
                                                  >(
                                                    value: g,
                                                    child: Text(groupLabel(g)),
                                                  ),
                                              ],
                                              onChanged: isSaving
                                                  ? null
                                                  : (v) => context
                                                        .read<
                                                          JournalManageLibraryBloc
                                                        >()
                                                        .moveTrackerToGroup(
                                                          def: d,
                                                          groupId: v?.id,
                                                        ),
                                            ),
                                      ),
                                      SizedBox(
                                        height: TasklyTokens.of(
                                          context,
                                        ).spaceSm,
                                      ),
                                      IconButton(
                                        tooltip: l10n.moveUpLabel,
                                        onPressed: isSaving
                                            ? null
                                            : () => context
                                                  .read<
                                                    JournalManageLibraryBloc
                                                  >()
                                                  .reorderTrackersWithinGroup(
                                                    trackerId: d.id,
                                                    groupId: d.groupId,
                                                    direction: -1,
                                                  ),
                                        icon: const Icon(Icons.arrow_upward),
                                      ),
                                      IconButton(
                                        tooltip: l10n.moveDownLabel,
                                        onPressed: isSaving
                                            ? null
                                            : () => context
                                                  .read<
                                                    JournalManageLibraryBloc
                                                  >()
                                                  .reorderTrackersWithinGroup(
                                                    trackerId: d.id,
                                                    groupId: d.groupId,
                                                    direction: 1,
                                                  ),
                                        icon: const Icon(Icons.arrow_downward),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
        ],
      ),
    );
  }
}

class _JournalNameDialog extends StatefulWidget {
  const _JournalNameDialog({
    required this.title,
    required this.initialValue,
    required this.labelText,
    required this.cancelLabel,
    required this.submitLabel,
    this.hintText,
  });

  final String title;
  final String initialValue;
  final String labelText;
  final String cancelLabel;
  final String submitLabel;
  final String? hintText;

  @override
  State<_JournalNameDialog> createState() => _JournalNameDialogState();
}

class _JournalNameDialogState extends State<_JournalNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _JournalNameBottomSheet extends StatefulWidget {
  const _JournalNameBottomSheet({
    required this.title,
    required this.initialValue,
    required this.labelText,
    required this.cancelLabel,
    required this.submitLabel,
  });

  final String title;
  final String initialValue;
  final String labelText;
  final String cancelLabel;
  final String submitLabel;

  @override
  State<_JournalNameBottomSheet> createState() =>
      _JournalNameBottomSheetState();
}

class _JournalNameBottomSheetState extends State<_JournalNameBottomSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: TasklyTokens.of(context).spaceLg,
        right: TasklyTokens.of(context).spaceLg,
        top: TasklyTokens.of(context).spaceLg,
        bottom:
            MediaQuery.viewInsetsOf(context).bottom +
            TasklyTokens.of(context).spaceLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.labelText),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          Row(
            children: [
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.cancelLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_controller.text),
                child: Text(widget.submitLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

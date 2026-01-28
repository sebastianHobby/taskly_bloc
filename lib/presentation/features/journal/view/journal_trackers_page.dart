import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_library_cubit.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalTrackersPage extends StatelessWidget {
  const JournalTrackersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalManageLibraryCubit>(
      create: (context) => JournalManageLibraryCubit(
        repository: context.read<JournalRepositoryContract>(),
        errorReporter: context.read<AppErrorReporter>(),
        nowUtc: context.read<NowService>().nowUtc,
      ),
      child: BlocConsumer<JournalManageLibraryCubit, JournalManageLibraryState>(
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

    List<TrackerGroup?> groupOptions() {
      return <TrackerGroup?>[null, ...groups];
    }

    String groupLabel(TrackerGroup? group) => group?.name ?? 'Ungrouped';

    List<TrackerDefinition> trackersForGroup(String? groupId) {
      final key = groupId ?? '';
      return trackers
          .where((d) => (d.groupId ?? '') == key)
          .toList(growable: false)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    Future<String?> showCreateGroupDialog() async {
      final controller = TextEditingController();
      try {
        final result = await showDialog<String>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('New group'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Health, Work, Habits',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(controller.text),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );

        final name = (result ?? '').trim();
        if (name.isEmpty) return null;
        return name;
      } finally {
        controller.dispose();
      }
    }

    Future<String?> showRenameDialog(String currentName) async {
      final controller = TextEditingController(text: currentName);
      try {
        final result = await showDialog<String>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Rename group'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(controller.text),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );

        final name = (result ?? '').trim();
        if (name.isEmpty) return null;
        return name;
      } finally {
        controller.dispose();
      }
    }

    Future<String?> showRenameTrackerBottomSheet(String currentName) async {
      final controller = TextEditingController(text: currentName);
      try {
        return await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                left: TasklyTokens.of(context).spaceLg,
                right: TasklyTokens.of(context).spaceLg,
                top: TasklyTokens.of(context).spaceLg,
                bottom: MediaQuery.viewInsetsOf(context).bottom +
                    TasklyTokens.of(context).spaceLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rename tracker',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Name'),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) =>
                        Navigator.of(context).pop(value),
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      } finally {
        controller.dispose();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage trackers'),
        actions: [
          IconButton(
            tooltip: 'New group',
            onPressed: isSaving
                ? null
                : () async {
                    final name = await showCreateGroupDialog();
                    if (name == null) return;
                    if (!context.mounted) return;
                    await context.read<JournalManageLibraryCubit>().createGroup(
                      name,
                    );
                  },
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          IconButton(
            tooltip: 'New tracker',
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
          Text('Groups', style: theme.textTheme.titleMedium),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          Card(
            child: Column(
              children: [
                if (groups.isEmpty)
                  const ListTile(
                    title: Text('No groups yet.'),
                  )
                else
                  for (final g in groups)
                    ListTile(
                      title: Text(g.name),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Move up',
                            onPressed: isSaving
                                ? null
                                : () => context
                                      .read<JournalManageLibraryCubit>()
                                      .reorderGroups(
                                        groupId: g.id,
                                        direction: -1,
                                      ),
                            icon: const Icon(Icons.arrow_upward),
                          ),
                          IconButton(
                            tooltip: 'Move down',
                            onPressed: isSaving
                                ? null
                                : () => context
                                      .read<JournalManageLibraryCubit>()
                                      .reorderGroups(
                                        groupId: g.id,
                                        direction: 1,
                                      ),
                            icon: const Icon(Icons.arrow_downward),
                          ),
                          IconButton(
                            tooltip: 'Rename',
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final name = await showRenameDialog(g.name);
                                    if (name == null) return;
                                    if (!context.mounted) return;
                                    await context
                                        .read<JournalManageLibraryCubit>()
                                        .renameGroup(group: g, name: name);
                                  },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: isSaving
                                ? null
                                : () => context
                                      .read<JournalManageLibraryCubit>()
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
          Text('Trackers', style: theme.textTheme.titleMedium),
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
                                  subtitle: Text('${d.valueType} • ${d.scope}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: d.isActive,
                                        onChanged: isSaving
                                            ? null
                                            : (v) => context
                                                  .read<
                                                    JournalManageLibraryCubit
                                                  >()
                                                  .setTrackerActive(
                                                    def: d,
                                                    isActive: v,
                                                  ),
                                      ),
                                      IconButton(
                                        tooltip: 'Rename',
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
                                                      JournalManageLibraryCubit
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
                                              decoration: const InputDecoration(
                                                labelText: 'Group',
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
                                                          JournalManageLibraryCubit
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
                                        tooltip: 'Move up',
                                        onPressed: isSaving
                                            ? null
                                            : () => context
                                                  .read<
                                                    JournalManageLibraryCubit
                                                  >()
                                                  .reorderTrackersWithinGroup(
                                                    trackerId: d.id,
                                                    groupId: d.groupId,
                                                    direction: -1,
                                                  ),
                                        icon: const Icon(Icons.arrow_upward),
                                      ),
                                      IconButton(
                                        tooltip: 'Move down',
                                        onPressed: isSaving
                                            ? null
                                            : () => context
                                                  .read<
                                                    JournalManageLibraryCubit
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

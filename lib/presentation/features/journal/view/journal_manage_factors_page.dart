import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_library_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalManageFactorsPage extends StatelessWidget {
  const JournalManageFactorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalManageLibraryBloc>(
      create: (context) => JournalManageLibraryBloc(
        repository: context.read<JournalRepositoryContract>(),
        errorReporter: context.read<AppErrorReporter>(),
        nowUtc: context.read<NowService>().nowUtc,
      ),
      child: const _ManageFactorsView(),
    );
  }
}

class _ManageFactorsView extends StatelessWidget {
  const _ManageFactorsView();

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.journalManageTrackersTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.journalTrackersTitle),
              Tab(text: context.l10n.groupsTitle),
            ],
          ),
        ),
        body: BlocConsumer<JournalManageLibraryBloc, JournalManageLibraryState>(
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
            if (state is JournalManageLibraryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is JournalManageLibraryError) {
              return Center(child: Text(state.message));
            }
            final loaded = state as JournalManageLibraryLoaded;
            final trackers =
                loaded.trackers
                    .where((d) => d.deletedAt == null && d.systemKey != 'mood')
                    .toList(growable: false)
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            final groups =
                loaded.groups.where((g) => g.isActive).toList(growable: false)
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

            final groupById = {for (final group in groups) group.id: group};

            return TabBarView(
              children: [
                ListView(
                  padding: EdgeInsets.all(tokens.spaceMd),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () =>
                            Routing.toJournalTrackerWizard(context),
                        icon: const Icon(Icons.add),
                        label: Text(context.l10n.journalNewTrackerTooltip),
                      ),
                    ),
                    SizedBox(height: tokens.spaceSm),
                    if (trackers.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: tokens.spaceMd),
                        child: Text(context.l10n.journalNoEntryTrackers),
                      ),
                    for (final tracker in trackers)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(trackerIconData(tracker)),
                          ),
                          title: Text(tracker.name),
                          subtitle: Text(
                            '${tracker.valueType} · ${groupById[tracker.groupId]?.name ?? context.l10n.allLabel}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'rename') {
                                final renamed = await _showNameSheet(
                                  context,
                                  title: context.l10n.journalRenameTrackerTitle,
                                  initialValue: tracker.name,
                                );
                                if (!context.mounted) return;
                                if (renamed == null || renamed.trim().isEmpty) {
                                  return;
                                }
                                await context
                                    .read<JournalManageLibraryBloc>()
                                    .renameTracker(
                                      def: tracker,
                                      name: renamed.trim(),
                                    );
                                return;
                              }
                              if (value == 'archive') {
                                await context
                                    .read<JournalManageLibraryBloc>()
                                    .setTrackerActive(
                                      def: tracker,
                                      isActive: false,
                                    );
                                return;
                              }
                              if (value == 'delete') {
                                await context
                                    .read<JournalManageLibraryBloc>()
                                    .deleteTracker(def: tracker);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'rename',
                                child: Text(context.l10n.renameLabel),
                              ),
                              PopupMenuItem<String>(
                                value: 'archive',
                                child: Text(context.l10n.journalArchiveLabel),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text(context.l10n.deleteLabel),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                ListView(
                  padding: EdgeInsets.all(tokens.spaceMd),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final name = await _showNameSheet(
                            context,
                            title: context.l10n.groupsTitle,
                            initialValue: '',
                          );
                          if (!context.mounted) return;
                          if (name == null || name.trim().isEmpty) return;
                          await context
                              .read<JournalManageLibraryBloc>()
                              .createGroup(name.trim());
                        },
                        icon: const Icon(Icons.add),
                        label: Text(context.l10n.groupsTitle),
                      ),
                    ),
                    SizedBox(height: tokens.spaceSm),
                    if (groups.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: tokens.spaceMd),
                        child: Text(context.l10n.journalNotSetLabel),
                      ),
                    for (final group in groups)
                      Card(
                        child: ListTile(
                          title: Text(group.name),
                          subtitle: Text('${group.sortOrder}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'rename') {
                                final renamed = await _showNameSheet(
                                  context,
                                  title: context.l10n.renameLabel,
                                  initialValue: group.name,
                                );
                                if (!context.mounted) return;
                                if (renamed == null || renamed.trim().isEmpty) {
                                  return;
                                }
                                await context
                                    .read<JournalManageLibraryBloc>()
                                    .renameGroup(
                                      group: group,
                                      name: renamed.trim(),
                                    );
                                return;
                              }
                              if (value == 'delete') {
                                await context
                                    .read<JournalManageLibraryBloc>()
                                    .deleteGroup(group);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'rename',
                                child: Text(context.l10n.renameLabel),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text(context.l10n.deleteLabel),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<String?> _showNameSheet(
    BuildContext context, {
    required String title,
    required String initialValue,
  }) {
    final controller = TextEditingController(text: initialValue);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final tokens = TasklyTokens.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
            left: tokens.spaceLg,
            right: tokens.spaceLg,
            top: tokens.spaceLg,
            bottom:
                MediaQuery.viewInsetsOf(sheetContext).bottom + tokens.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
              SizedBox(height: tokens.spaceSm),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) => Navigator.of(sheetContext).pop(value),
              ),
              SizedBox(height: tokens.spaceSm),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(sheetContext.l10n.cancelLabel),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(controller.text),
                    child: Text(sheetContext.l10n.saveLabel),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

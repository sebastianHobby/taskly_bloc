import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_library_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_icons.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalDailyCheckinsPage extends StatelessWidget {
  const JournalDailyCheckinsPage({super.key});

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
            JournalManageLibraryLoaded(:final trackers, :final status) =>
              _DailyCheckinsView(trackers: trackers, status: status),
          };
        },
      ),
    );
  }
}

class _DailyCheckinsView extends StatelessWidget {
  const _DailyCheckinsView({
    required this.trackers,
    required this.status,
  });

  final List<TrackerDefinition> trackers;
  final JournalManageLibraryStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = TasklyTokens.of(context);
    final isSaving = status is JournalManageLibrarySaving;

    final dailyTrackers =
        trackers
            .where((d) => _isDailyScope(d) && d.systemKey != 'mood')
            .toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journalDailyCheckInsTitle),
        actions: [
          IconButton(
            tooltip: l10n.journalNewDailyCheckInTooltip,
            onPressed: isSaving
                ? null
                : () => Routing.toJournalDailyCheckinWizard(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLg,
              tokens.spaceMd,
              tokens.spaceLg,
              tokens.spaceSm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: tokens.spaceXs),
                Expanded(
                  child: Text(
                    l10n.journalDailyCheckinsLockedHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: dailyTrackers.isEmpty
                ? Center(child: Text(l10n.journalNoDailyCheckIns))
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spaceMd,
                      0,
                      tokens.spaceMd,
                      tokens.spaceXl,
                    ),
                    itemCount: dailyTrackers.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: tokens.spaceSm),
                    itemBuilder: (context, index) {
                      final d = dailyTrackers[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(trackerIconData(d)),
                          ),
                          title: Text(d.name),
                          subtitle: Text(
                            '${d.valueType} - ${l10n.journalDailyAppliesTodaySubtitle}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'rename') {
                                final renamed = await _showRenameSheet(
                                  context,
                                  title: l10n.journalRenameTrackerTitle,
                                  initialValue: d.name,
                                );
                                if (renamed == null || renamed.trim().isEmpty) {
                                  return;
                                }
                                if (!context.mounted) return;
                                await context
                                    .read<JournalManageLibraryBloc>()
                                    .renameTracker(
                                      def: d,
                                      name: renamed.trim(),
                                    );
                                return;
                              }
                              if (value == 'icon') {
                                final selected = await _showIconSheet(
                                  context,
                                  selectedIconName: effectiveTrackerIconName(d),
                                );
                                if (selected == null || !context.mounted) {
                                  return;
                                }
                                await context
                                    .read<JournalManageLibraryBloc>()
                                    .setTrackerIcon(def: d, iconName: selected);
                                return;
                              }
                              if (value == 'archive') {
                                await context
                                    .read<JournalManageLibraryBloc>()
                                    .setTrackerActive(def: d, isActive: false);
                                return;
                              }
                              if (value == 'delete') {
                                final action = await _showDeleteTrackerDialog(
                                  context,
                                  trackerName: d.name,
                                );
                                if (!context.mounted || action == null) {
                                  return;
                                }
                                if (action == _DeleteTrackerAction.archive) {
                                  await context
                                      .read<JournalManageLibraryBloc>()
                                      .setTrackerActive(
                                        def: d,
                                        isActive: false,
                                      );
                                  return;
                                }
                                await context
                                    .read<JournalManageLibraryBloc>()
                                    .deleteTracker(def: d);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'rename',
                                child: Text(l10n.renameLabel),
                              ),
                              PopupMenuItem<String>(
                                value: 'icon',
                                child: Text(l10n.valueFormIconLabel),
                              ),
                              PopupMenuItem<String>(
                                value: 'archive',
                                child: Text(l10n.journalArchiveLabel),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text(l10n.deleteLabel),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _isDailyScope(TrackerDefinition d) {
    final scope = d.scope.trim().toLowerCase();
    return scope == 'day' || scope == 'daily' || scope == 'sleep_night';
  }

  Future<String?> _showRenameSheet(
    BuildContext context, {
    required String title,
    required String initialValue,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _NameBottomSheet(
        title: title,
        initialValue: initialValue,
        labelText: sheetContext.l10n.nameLabel,
        cancelLabel: sheetContext.l10n.cancelLabel,
        submitLabel: sheetContext.l10n.saveLabel,
      ),
    );
  }

  Future<String?> _showIconSheet(
    BuildContext context, {
    required String? selectedIconName,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          TasklyTokens.of(sheetContext).spaceLg,
          TasklyTokens.of(sheetContext).spaceSm,
          TasklyTokens.of(sheetContext).spaceLg,
          TasklyTokens.of(sheetContext).spaceLg,
        ),
        child: TasklyFormIconSearchPicker(
          icons: tasklySymbolIcons,
          selectedIconName: selectedIconName,
          searchHintText: sheetContext.l10n.valueFormIconSearchHint,
          noIconsFoundLabel: sheetContext.l10n.valueFormIconNoResults,
          tooltipBuilder: formatIconLabel,
          onSelected: (iconName) => Navigator.of(sheetContext).pop(iconName),
        ),
      ),
    );
  }

  Future<_DeleteTrackerAction?> _showDeleteTrackerDialog(
    BuildContext context, {
    required String trackerName,
  }) {
    final l10n = context.l10n;
    return showDialog<_DeleteTrackerAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.journalDeleteTrackerTitle),
          content: Text(
            l10n.journalDeleteTrackerMessage(trackerName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                _DeleteTrackerAction.archive,
              ),
              child: Text(l10n.journalArchiveInsteadLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                _DeleteTrackerAction.delete,
              ),
              child: Text(l10n.deleteLabel),
            ),
          ],
        );
      },
    );
  }
}

enum _DeleteTrackerAction { archive, delete }

class _NameBottomSheet extends StatefulWidget {
  const _NameBottomSheet({
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
  State<_NameBottomSheet> createState() => _NameBottomSheetState();
}

class _NameBottomSheetState extends State<_NameBottomSheet> {
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
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
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

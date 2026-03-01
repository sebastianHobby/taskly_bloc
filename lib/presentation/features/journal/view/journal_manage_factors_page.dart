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

class _ManageFactorsView extends StatefulWidget {
  const _ManageFactorsView();

  @override
  State<_ManageFactorsView> createState() => _ManageFactorsViewState();
}

class _ManageFactorsViewState extends State<_ManageFactorsView> {
  bool _showAggregate = false;

  bool _isAggregate(TrackerDefinition definition) {
    return definition.opKind.trim().toLowerCase() == 'add' ||
        definition.scope.trim().toLowerCase() == 'day' ||
        definition.aggregationKind.trim().toLowerCase() == 'avg';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.journalManageTrackersTitle),
        actions: [
          IconButton(
            onPressed: () => Routing.toJournalTrackerTypeSelection(context),
            icon: const Icon(Icons.add),
            tooltip: context.l10n.journalNewTrackerTooltip,
          ),
        ],
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
          final groups = loaded.groups.where((g) => g.isActive).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          final trackers =
              loaded.trackers
                  .where((d) => d.deletedAt == null)
                  .where(
                    (d) => _showAggregate ? _isAggregate(d) : !_isAggregate(d),
                  )
                  .toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return ListView(
            padding: EdgeInsets.all(tokens.spaceMd),
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(context.l10n.journalTrackerTypeActivityTitle),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(context.l10n.journalTrackerTypeAggregateTitle),
                  ),
                ],
                selected: <bool>{_showAggregate},
                onSelectionChanged: (selected) {
                  if (selected.isEmpty) return;
                  setState(() {
                    _showAggregate = selected.first;
                  });
                },
              ),
              SizedBox(height: tokens.spaceSm),
              if (trackers.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: tokens.spaceMd),
                  child: Text(context.l10n.journalNoEntryTrackers),
                ),
              ..._buildGroupedTrackers(
                context: context,
                groups: groups,
                trackers: trackers,
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedTrackers({
    required BuildContext context,
    required List<TrackerGroup> groups,
    required List<TrackerDefinition> trackers,
  }) {
    final tokens = TasklyTokens.of(context);
    final byGroup = <String?, List<TrackerDefinition>>{};
    for (final tracker in trackers) {
      (byGroup[tracker.groupId] ??= <TrackerDefinition>[]).add(tracker);
    }

    final widgets = <Widget>[];

    for (final group in groups) {
      final defs = byGroup[group.id] ?? const <TrackerDefinition>[];
      if (defs.isEmpty) continue;
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: tokens.spaceSm, bottom: tokens.spaceXs),
          child: Text(
            group.name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      );
      for (final tracker in defs) {
        widgets.add(_TrackerRow(tracker: tracker));
      }
    }

    final ungrouped = byGroup[null] ?? const <TrackerDefinition>[];
    if (ungrouped.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: tokens.spaceSm, bottom: tokens.spaceXs),
          child: Text(
            context.l10n.allLabel,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      );
      for (final tracker in ungrouped) {
        widgets.add(_TrackerRow(tracker: tracker));
      }
    }

    return widgets;
  }
}

class _TrackerRow extends StatelessWidget {
  const _TrackerRow({required this.tracker});

  final TrackerDefinition tracker;

  bool get _isSystem => tracker.source.trim().toLowerCase() == 'system';

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: tokens.spaceXs),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(tokens.radiusSm),
          ),
          child: Icon(trackerIconData(tracker)),
        ),
        title: Text(
          tracker.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_subtitleText()),
        trailing: _isSystem
            ? Switch(
                value: tracker.isActive,
                onChanged: (value) {
                  context.read<JournalManageLibraryBloc>().setTrackerActive(
                    def: tracker,
                    isActive: value,
                  );
                },
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: context.l10n.renameLabel,
                    onPressed: () async {
                      final action = await showModalBottomSheet<String>(
                        context: context,
                        showDragHandle: true,
                        useSafeArea: true,
                        builder: (sheetContext) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit_outlined),
                                title: Text(sheetContext.l10n.renameLabel),
                                onTap: () =>
                                    Navigator.of(sheetContext).pop('rename'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.palette_outlined),
                                title: Text(sheetContext.l10n.changeIconLabel),
                                onTap: () =>
                                    Navigator.of(sheetContext).pop('icon'),
                              ),
                              ListTile(
                                leading: Icon(
                                  tracker.isActive
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                title: Text(
                                  tracker.isActive
                                      ? sheetContext.l10n.deactivateLabel
                                      : sheetContext.l10n.activateLabel,
                                ),
                                onTap: () => Navigator.of(sheetContext).pop(
                                  'active',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (!context.mounted || action == null) return;
                      if (action == 'active') {
                        await context
                            .read<JournalManageLibraryBloc>()
                            .setTrackerActive(
                              def: tracker,
                              isActive: !tracker.isActive,
                            );
                        return;
                      }
                      if (action == 'icon') {
                        final selected = await _showIconPickerSheet(
                          context,
                          selectedIconName: trackerIconNameFromConfig(
                            tracker.config,
                          ),
                        );
                        if (!context.mounted || selected == null) return;
                        await context
                            .read<JournalManageLibraryBloc>()
                            .setTrackerIcon(
                              def: tracker,
                              iconName: selected,
                            );
                        return;
                      }
                      final renamed = await _showNameSheet(
                        context,
                        title: context.l10n.journalRenameTrackerTitle,
                        initialValue: tracker.name,
                      );
                      if (!context.mounted ||
                          renamed == null ||
                          renamed.trim().isEmpty) {
                        return;
                      }
                      await context
                          .read<JournalManageLibraryBloc>()
                          .renameTracker(
                            def: tracker,
                            name: renamed.trim(),
                          );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: context.l10n.deleteLabel,
                    onPressed: () => context
                        .read<JournalManageLibraryBloc>()
                        .deleteTracker(def: tracker),
                  ),
                ],
              ),
      ),
    );
  }

  String _subtitleText() {
    final description = tracker.description?.trim();
    if (description != null && description.isNotEmpty) return description;
    final type = tracker.valueType.trim().toLowerCase();
    return switch (type) {
      'yes_no' => 'Yes/No',
      'quantity' =>
        tracker.unitKind == null
            ? 'Quantity'
            : 'Quantity - ${tracker.unitKind}',
      'rating' => 'Rating',
      'choice' || 'single_choice' => 'Choice',
      _ => tracker.valueType,
    };
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

  Future<String?> _showIconPickerSheet(
    BuildContext context, {
    required String? selectedIconName,
  }) {
    final tokens = TasklyTokens.of(context);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          child: TasklyFormIconSearchPicker(
            icons: tasklySymbolIcons,
            selectedIconName: selectedIconName,
            searchHintText: sheetContext.l10n.valueFormIconSearchHint,
            noIconsFoundLabel: sheetContext.l10n.valueFormIconNoResults,
            tooltipBuilder: formatIconLabel,
            onSelected: (iconName) => Navigator.of(sheetContext).pop(iconName),
          ),
        );
      },
    );
  }
}

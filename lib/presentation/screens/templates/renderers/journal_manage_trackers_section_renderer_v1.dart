import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_trackers_cubit.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/tracker_editor_sheet.dart';

final class JournalManageTrackersSectionRendererV1 extends StatefulWidget {
  const JournalManageTrackersSectionRendererV1({
    required this.definitions,
    required this.preferenceByTrackerId,
    super.key,
  });

  final List<TrackerDefinition> definitions;
  final Map<String, TrackerPreference> preferenceByTrackerId;

  @override
  State<JournalManageTrackersSectionRendererV1> createState() =>
      _JournalManageTrackersSectionRendererV1State();
}

enum _TrackerTab { active, archived, system }

final class _JournalManageTrackersSectionRendererV1State
    extends State<JournalManageTrackersSectionRendererV1> {
  final _searchController = TextEditingController();

  _TrackerTab _tab = _TrackerTab.active;
  bool _filterPinned = false;
  bool _filterQuickAdd = false;
  bool _filterOutcome = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalManageTrackersCubit>(
      create: (_) => getIt<JournalManageTrackersCubit>(),
      child:
          BlocListener<JournalManageTrackersCubit, JournalManageTrackersState>(
            listenWhen: (prev, next) =>
                prev.status.runtimeType != next.status.runtimeType,
            listener: (context, state) {
              if (state.status case JournalManageTrackersError(
                :final message,
              )) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Builder(
              builder: (context) {
                final all = widget.definitions;
                final prefs = widget.preferenceByTrackerId;

                final userDefinitions =
                    all
                        .where((d) => d.deletedAt == null)
                        .where((d) => d.systemKey == null)
                        .toList(growable: false)
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                final active = userDefinitions
                    .where((d) => d.isActive)
                    .toList(growable: false);
                final archived = userDefinitions
                    .where((d) => !d.isActive)
                    .toList(growable: false);

                final system =
                    all
                        .where((d) => d.deletedAt == null)
                        .where((d) => d.systemKey != null)
                        .toList(growable: false)
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                final search = _searchController.text.trim().toLowerCase();

                final (visibleList, canReorder) = switch (_tab) {
                  _TrackerTab.active => (
                    _applyFilters(
                      list: active,
                      prefs: prefs,
                      search: search,
                      filterPinned: _filterPinned,
                      filterQuickAdd: _filterQuickAdd,
                      filterOutcome: _filterOutcome,
                    ),
                    search.isEmpty &&
                        !_filterPinned &&
                        !_filterQuickAdd &&
                        !_filterOutcome,
                  ),
                  _TrackerTab.archived => (
                    _applyFilters(
                      list: archived,
                      prefs: prefs,
                      search: search,
                      filterPinned: _filterPinned,
                      filterQuickAdd: _filterQuickAdd,
                      filterOutcome: _filterOutcome,
                    ),
                    false,
                  ),
                  _TrackerTab.system => (
                    _applyFilters(
                      list: system,
                      prefs: prefs,
                      search: search,
                      filterPinned: false,
                      filterQuickAdd: false,
                      filterOutcome: _filterOutcome,
                    ),
                    false,
                  ),
                };

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Trackers',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        BlocBuilder<
                          JournalManageTrackersCubit,
                          JournalManageTrackersState
                        >(
                          builder: (context, state) {
                            final busy =
                                state.status is JournalManageTrackersSaving;
                            return FilledButton.icon(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      await _openEditorCreate(
                                        context,
                                        sortBase: userDefinitions.isEmpty
                                            ? 90
                                            : userDefinitions
                                                  .map((d) => d.sortOrder)
                                                  .reduce(
                                                    (a, b) => a > b ? a : b,
                                                  ),
                                      );
                                    },
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<_TrackerTab>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: _TrackerTab.active,
                          label: Text('Active (${active.length})'),
                        ),
                        ButtonSegment(
                          value: _TrackerTab.archived,
                          label: Text('Archived (${archived.length})'),
                        ),
                        ButtonSegment(
                          value: _TrackerTab.system,
                          label: Text('System (${system.length})'),
                        ),
                      ],
                      selected: <_TrackerTab>{_tab},
                      onSelectionChanged: (s) {
                        final next = s.first;
                        setState(() {
                          _tab = next;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_tab != _TrackerTab.system)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Pinned'),
                            selected: _filterPinned,
                            onSelected: (v) =>
                                setState(() => _filterPinned = v),
                          ),
                          FilterChip(
                            label: const Text('Quick add'),
                            selected: _filterQuickAdd,
                            onSelected: (v) =>
                                setState(() => _filterQuickAdd = v),
                          ),
                          FilterChip(
                            label: const Text('Outcome'),
                            selected: _filterOutcome,
                            onSelected: (v) =>
                                setState(() => _filterOutcome = v),
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Outcome'),
                            selected: _filterOutcome,
                            onSelected: (v) =>
                                setState(() => _filterOutcome = v),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    if (active.isEmpty && archived.isEmpty && system.isEmpty)
                      const Text('No trackers yet.'),
                    if (visibleList.isEmpty &&
                        !(active.isEmpty && archived.isEmpty && system.isEmpty))
                      Text(
                        search.isEmpty
                            ? 'Nothing here yet.'
                            : 'No matches for "$search".',
                      ),
                    if (visibleList.isNotEmpty) ...[
                      if (_tab == _TrackerTab.active && canReorder)
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) async {
                            final list = [...visibleList];
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = list.removeAt(oldIndex);
                            list.insert(newIndex, item);

                            await context
                                .read<JournalManageTrackersCubit>()
                                .reorderDefinitions(ordered: list);
                          },
                          children: [
                            for (final (index, d) in visibleList.indexed)
                              _TrackerCard(
                                key: ValueKey('tracker_${d.id}'),
                                definition: d,
                                preference: prefs[d.id],
                                dragIndex: index,
                                onEdit: () => _openEditorEdit(
                                  context,
                                  definition: d,
                                  preference: prefs[d.id],
                                ),
                              ),
                          ],
                        )
                      else
                        for (final d in visibleList)
                          _TrackerCard(
                            key: ValueKey('tracker_${d.id}'),
                            definition: d,
                            preference: prefs[d.id],
                            onEdit: () => _openEditorEdit(
                              context,
                              definition: d,
                              preference: prefs[d.id],
                            ),
                          ),
                    ],
                  ],
                );
              },
            ),
          ),
    );
  }

  Future<void> _openEditorCreate(
    BuildContext context, {
    required int sortBase,
  }) async {
    final nowUtc = getIt<NowService>().nowUtc();
    final result = await showTrackerEditorSheet(context: context);
    if (!context.mounted) return;
    if (result == null) return;

    final definition = result.definition.copyWith(
      createdAt: nowUtc,
      updatedAt: nowUtc,
      sortOrder: sortBase + 10,
      systemKey: null,
      deletedAt: null,
      id: '',
    );

    await context.read<JournalManageTrackersCubit>().upsertTrackerFromEditor(
      definition: definition,
      pinned: result.pinned,
      showInQuickAdd: result.showInQuickAdd,
      choices: result.choices,
    );
  }

  Future<void> _openEditorEdit(
    BuildContext context, {
    required TrackerDefinition definition,
    required TrackerPreference? preference,
  }) async {
    if (definition.systemKey != null) return;

    final cubit = context.read<JournalManageTrackersCubit>();
    final initialChoices = definition.valueType == 'choice'
        ? await cubit.getChoices(definition.id)
        : const <TrackerDefinitionChoice>[];

    if (!context.mounted) return;

    final result = await showTrackerEditorSheet(
      context: context,
      initialDefinition: definition,
      initialPinned: preference?.pinned ?? false,
      initialShowInQuickAdd: preference?.showInQuickAdd ?? false,
      initialChoices: initialChoices,
    );
    if (!context.mounted) return;
    if (result == null) return;

    await cubit.upsertTrackerFromEditor(
      definition: result.definition.copyWith(
        updatedAt: getIt<NowService>().nowUtc(),
      ),
      pinned: result.pinned,
      showInQuickAdd: result.showInQuickAdd,
      existingPreference: preference,
      choices: result.choices,
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({
    required this.definition,
    required this.preference,
    required this.onEdit,
    this.dragIndex,
    super.key,
  });

  final TrackerDefinition definition;
  final TrackerPreference? preference;
  final VoidCallback onEdit;
  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    final pref = preference;
    final pinned = pref?.pinned ?? false;
    final quickAdd = pref?.showInQuickAdd ?? false;
    final readOnly = definition.systemKey != null;

    final subtitle = _trackerSubtitle(definition);

    return Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            ListTile(
              leading: dragIndex == null
                  ? Icon(readOnly ? Icons.lock_outline : Icons.label_outline)
                  : ReorderableDragStartListener(
                      index: dragIndex!,
                      child: const Icon(Icons.drag_handle),
                    ),
              title: Text(definition.name),
              subtitle: Text(subtitle),
              onTap: readOnly ? null : onEdit,
              trailing: PopupMenuButton<_TrackerAction>(
                onSelected: (action) async {
                  final cubit = context.read<JournalManageTrackersCubit>();
                  switch (action) {
                    case _TrackerAction.edit:
                      onEdit();
                    case _TrackerAction.archive:
                      await cubit.setArchived(
                        definition: definition,
                        archived: true,
                      );
                    case _TrackerAction.unarchive:
                      await cubit.setArchived(
                        definition: definition,
                        archived: false,
                      );
                    case _TrackerAction.delete:
                      final confirmed = await _confirmDelete(
                        context,
                        definition,
                      );
                      if (!context.mounted) return;
                      if (confirmed != true) return;
                      await cubit.deleteTrackerAndData(definition: definition);
                  }
                },
                itemBuilder: (context) => [
                  if (!readOnly)
                    const PopupMenuItem(
                      value: _TrackerAction.edit,
                      child: Text('Edit…'),
                    ),
                  if (definition.isActive)
                    const PopupMenuItem(
                      value: _TrackerAction.archive,
                      child: Text('Archive'),
                    )
                  else
                    const PopupMenuItem(
                      value: _TrackerAction.unarchive,
                      child: Text('Unarchive'),
                    ),
                  if (!readOnly)
                    const PopupMenuItem(
                      value: _TrackerAction.delete,
                      child: Text('Delete…'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pinned'),
                    value: pinned,
                    onChanged: (!readOnly && definition.isActive)
                        ? (value) => context
                              .read<JournalManageTrackersCubit>()
                              .setPinned(
                                definition: definition,
                                existing: pref,
                                pinned: value,
                              )
                        : null,
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show in quick add'),
                    value: quickAdd,
                    onChanged: (!readOnly && definition.isActive)
                        ? (value) => context
                              .read<JournalManageTrackersCubit>()
                              .setShowInQuickAdd(
                                definition: definition,
                                existing: pref,
                                showInQuickAdd: value,
                              )
                        : null,
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Outcome (vs factor)'),
                    value: definition.isOutcome,
                    onChanged: (!readOnly && definition.isActive)
                        ? (value) => context
                              .read<JournalManageTrackersCubit>()
                              .setOutcome(
                                definition: definition,
                                isOutcome: value,
                              )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    TrackerDefinition definition,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete tracker?'),
          content: Text(
            'This deletes "${definition.name}" and removes its local history and stats. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

enum _TrackerAction { edit, archive, unarchive, delete }

List<TrackerDefinition> _applyFilters({
  required List<TrackerDefinition> list,
  required Map<String, TrackerPreference> prefs,
  required String search,
  required bool filterPinned,
  required bool filterQuickAdd,
  required bool filterOutcome,
}) {
  return list
      .where((d) {
        if (filterOutcome && !d.isOutcome) return false;

        final pref = prefs[d.id];
        if (filterPinned && !(pref?.pinned ?? false)) return false;
        if (filterQuickAdd && !(pref?.showInQuickAdd ?? false)) return false;

        if (search.isEmpty) return true;
        final haystack = '${d.name} ${d.description ?? ''} ${d.valueType}'
            .toLowerCase();
        return haystack.contains(search);
      })
      .toList(growable: false);
}

String _trackerSubtitle(TrackerDefinition d) {
  final kind = switch (d.valueType) {
    'yes_no' => 'Yes/No',
    'rating' => 'Rating',
    'choice' => 'Choice',
    'number' || 'int' => 'Number',
    _ => d.valueType,
  };

  final range = (d.minInt != null && d.maxInt != null)
      ? ' ${d.minInt}-${d.maxInt}'
      : '';
  final unit = (d.unitKind != null && d.unitKind!.trim().isNotEmpty)
      ? ' • ${d.unitKind!.trim()}'
      : '';
  final outcome = d.isOutcome ? 'Outcome' : 'Factor';
  return '$kind$range$unit • $outcome';
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search trackers',
        border: const OutlineInputBorder(),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

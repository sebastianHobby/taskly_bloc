import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';

class JournalTrackersPage extends StatelessWidget {
  const JournalTrackersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = getIt<JournalRepositoryContract>();

    return StreamBuilder<List<TrackerDefinition>>(
      stream: repo.watchTrackerDefinitions(),
      builder: (context, defsSnapshot) {
        if (defsSnapshot.hasError) {
          return const Center(child: Text('Failed to load trackers.'));
        }
        if (!defsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final definitions = defsSnapshot.data ?? const <TrackerDefinition>[];

        return StreamBuilder<List<TrackerPreference>>(
          stream: repo.watchTrackerPreferences(),
          builder: (context, prefsSnapshot) {
            if (prefsSnapshot.hasError) {
              return const Center(child: Text('Failed to load preferences.'));
            }
            if (!prefsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final prefs = prefsSnapshot.data ?? const <TrackerPreference>[];
            final prefsByTrackerId = {
              for (final p in prefs) p.trackerId: p,
            };

            final visible =
                definitions
                    .where((d) => d.deletedAt == null)
                    .toList(
                      growable: false,
                    )
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: visible.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CreateTrackerCard(
                    onCreate: (name) async {
                      final nowUtc = DateTime.now().toUtc();
                      await repo.saveTrackerDefinition(
                        TrackerDefinition(
                          id: '',
                          name: name,
                          description: null,
                          scope: 'entry',
                          valueType: 'yes_no',
                          valueKind: 'boolean',
                          opKind: 'set',
                          createdAt: nowUtc,
                          updatedAt: nowUtc,
                          roles: const <String>[],
                          config: const <String, dynamic>{},
                          goal: const <String, dynamic>{},
                          isActive: true,
                          sortOrder: visible.length * 10 + 100,
                          deletedAt: null,
                          source: 'user',
                          systemKey: null,
                          minInt: null,
                          maxInt: null,
                          stepInt: null,
                          linkedValueId: null,
                          isOutcome: false,
                          isInsightEnabled: false,
                          higherIsBetter: null,
                          unitKind: null,
                          userId: null,
                        ),
                      );
                    },
                  );
                }

                if (visible.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                    child: Center(child: Text('No trackers yet.')),
                  );
                }

                final definition = visible[index - 1];
                final pref = prefsByTrackerId[definition.id];

                return _TrackerRow(
                  definition: definition,
                  preference: pref,
                  onChanged: repo.saveTrackerPreference,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CreateTrackerCard extends StatelessWidget {
  const _CreateTrackerCard({required this.onCreate});

  final ValueChanged<String> onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.add),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Create tracker',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton(
              onPressed: () => _showCreateDialog(context),
              child: const Text('New'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final controller = TextEditingController();
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('New tracker'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Read, Walk, Stretch',
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
      if (name.isEmpty) return;
      onCreate(name);
    } finally {
      controller.dispose();
    }
  }
}

class _TrackerRow extends StatelessWidget {
  const _TrackerRow({
    required this.definition,
    required this.preference,
    required this.onChanged,
  });

  final TrackerDefinition definition;
  final TrackerPreference? preference;
  final ValueChanged<TrackerPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();

    final pref =
        preference ??
        TrackerPreference(
          id: '',
          trackerId: definition.id,
          createdAt: now,
          updatedAt: now,
          isActive: true,
          sortOrder: definition.sortOrder,
          pinned: false,
          showInQuickAdd: false,
        );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    definition.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: pref.isActive,
                  onChanged: (value) {
                    onChanged(
                      pref.copyWith(
                        isActive: value,
                        updatedAt: DateTime.now().toUtc(),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (definition.description != null &&
                definition.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                definition.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pinned'),
                    value: pref.pinned,
                    onChanged: (value) {
                      if (value == null) return;
                      onChanged(
                        pref.copyWith(
                          pinned: value,
                          updatedAt: DateTime.now().toUtc(),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Quick add'),
                    value: pref.showInQuickAdd,
                    onChanged: (value) {
                      if (value == null) return;
                      onChanged(
                        pref.copyWith(
                          showInQuickAdd: value,
                          updatedAt: DateTime.now().toUtc(),
                        ),
                      );
                    },
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

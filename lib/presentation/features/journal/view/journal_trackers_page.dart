import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_domain/domain/journal/model/tracker_definition.dart';
import 'package:taskly_domain/domain/journal/model/tracker_preference.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_trackers_cubit.dart';

class JournalTrackersPage extends StatelessWidget {
  const JournalTrackersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalTrackersCubit>(
      create: (_) => getIt<JournalTrackersCubit>(),
      child: BlocBuilder<JournalTrackersCubit, JournalTrackersState>(
        builder: (context, state) {
          return switch (state) {
            JournalTrackersLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            JournalTrackersError(:final message) => Center(
              child: Text(message),
            ),
            JournalTrackersLoaded(
              :final visibleDefinitions,
              :final preferenceByTrackerId,
            ) =>
              _JournalTrackersLoadedView(
                visibleDefinitions: visibleDefinitions,
                preferenceByTrackerId: preferenceByTrackerId,
              ),
          };
        },
      ),
    );
  }
}

class _JournalTrackersLoadedView extends StatelessWidget {
  const _JournalTrackersLoadedView({
    required this.visibleDefinitions,
    required this.preferenceByTrackerId,
  });

  final List<TrackerDefinition> visibleDefinitions;
  final Map<String, TrackerPreference> preferenceByTrackerId;

  @override
  Widget build(BuildContext context) {
    final extraRows = visibleDefinitions.isEmpty ? 1 : 0;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: visibleDefinitions.length + 1 + extraRows,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CreateTrackerCard(
            onCreate: (name) {
              context.read<JournalTrackersCubit>().createTracker(name);
            },
          );
        }

        if (visibleDefinitions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 24,
            ),
            child: Center(child: Text('No trackers yet.')),
          );
        }

        final definition = visibleDefinitions[index - 1];
        final pref = preferenceByTrackerId[definition.id];

        return _TrackerRow(
          definition: definition,
          preference: pref,
          onChanged: (p) {
            context.read<JournalTrackersCubit>().savePreference(p);
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

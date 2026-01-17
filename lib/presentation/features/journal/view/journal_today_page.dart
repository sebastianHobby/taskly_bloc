import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_today_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/add_log_sheet.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

class JournalTodayPage extends StatelessWidget {
  const JournalTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalTodayBloc>(
      create: (_) => getIt<JournalTodayBloc>(),
      child: BlocBuilder<JournalTodayBloc, JournalTodayState>(
        builder: (context, state) {
          return switch (state) {
            JournalTodayLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            JournalTodayError(:final message) => _ErrorState(message: message),
            JournalTodayLoaded(
              :final pinnedTrackers,
              :final entries,
              :final eventsByEntryId,
              :final definitionById,
              :final moodTrackerId,
            ) =>
              ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                children: [
                  JournalTodayComposer(
                    pinnedTrackers: pinnedTrackers,
                    onAddLog: () => AddLogSheet.show(context: context),
                    onQuickAddTracker: (trackerId) => AddLogSheet.show(
                      context: context,
                      preselectedTrackerIds: {trackerId},
                    ),
                  ),
                  const SizedBox(height: 16),
                  JournalTodayEntriesSection(
                    entries: entries,
                    eventsByEntryId: eventsByEntryId,
                    definitionById: definitionById,
                    moodTrackerId: moodTrackerId,
                    onEntryTap: (entry) => Routing.toJournalEntryEdit(
                      context,
                      entry.id,
                    ),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/domain/models/wellbeing/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response_config.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tracker_response_fields.dart';

/// Section for managing allDay tracker responses.
///
/// AllDay trackers persist across all entries for a given day. When marked
/// as done (e.g., exercise at 9am), the status shows across all entries
/// created that day. Users can update or clear responses at any time.
class DailyTrackerSection extends StatelessWidget {
  const DailyTrackerSection({
    required this.formKey,
    required this.trackers,
    required this.existingResponses,
    required this.selectedDate,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final List<Tracker> trackers;
  final List<DailyTrackerResponse> existingResponses;
  final DateTime selectedDate;

  Map<String, DailyTrackerResponse> get _responsesByTrackerId {
    return {for (final r in existingResponses) r.trackerId: r};
  }

  @override
  Widget build(BuildContext context) {
    if (trackers.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final responseMap = _responsesByTrackerId;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Trackers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'All Day',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'These apply to your entire day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),

            // Tracker fields
            ...trackers.map((tracker) {
              final existingResponse = responseMap[tracker.id];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DailyTrackerField(
                  tracker: tracker,
                  existingResponse: existingResponse,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DailyTrackerField extends StatelessWidget {
  const _DailyTrackerField({
    required this.tracker,
    this.existingResponse,
  });

  final Tracker tracker;
  final DailyTrackerResponse? existingResponse;

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = 'daily_tracker_${tracker.id}';
    final hasExisting = existingResponse != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasExisting
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasExisting
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: hasExisting ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracker.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (tracker.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        tracker.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status indicator
              if (hasExisting) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(existingResponse!.updatedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildField(name),
        ],
      ),
    );
  }

  Widget _buildField(String name) {
    final initialValue = existingResponse?.value;

    return switch (tracker.responseType) {
      TrackerResponseType.yesNo => FormBuilderTrackerYesNoField(
        name: name,
        initialValue: initialValue,
      ),
      TrackerResponseType.scale => switch (tracker.config) {
        ScaleConfig(:final min, :final max, :final minLabel, :final maxLabel) =>
          FormBuilderTrackerScaleField(
            name: name,
            min: min,
            max: max,
            minLabel: minLabel,
            maxLabel: maxLabel,
            initialValue: initialValue,
          ),
        _ => const SizedBox.shrink(),
      },
      TrackerResponseType.choice => switch (tracker.config) {
        ChoiceConfig(:final options) => FormBuilderTrackerChoiceField(
          name: name,
          options: options,
          initialValue: initialValue,
        ),
        _ => const SizedBox.shrink(),
      },
    };
  }
}

/// Helper widget to display a summary of daily tracker completions.
///
/// Shows as a compact row of completed tracker indicators, useful for
/// the header or timeline views.
class DailyTrackersSummary extends StatelessWidget {
  const DailyTrackersSummary({
    required this.trackers,
    required this.responses,
    super.key,
  });

  final List<Tracker> trackers;
  final List<DailyTrackerResponse> responses;

  @override
  Widget build(BuildContext context) {
    if (trackers.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final responseMap = {for (final r in responses) r.trackerId: r};
    final completed = responses.length;
    final total = trackers.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: completed == total
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed == total ? Icons.check_circle : Icons.pending,
            size: 18,
            color: completed == total
                ? Colors.green
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Daily: $completed/$total',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: completed == total
                  ? Colors.green.shade700
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (completed > 0) ...[
            const SizedBox(width: 8),
            // Show completed tracker icons
            ...trackers.take(5).map((tracker) {
              final isComplete = responseMap.containsKey(tracker.id);
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isComplete ? Colors.green : theme.dividerColor,
                  ),
                ),
              );
            }),
            if (trackers.length > 5)
              Text(
                '+${trackers.length - 5}',
                style: theme.textTheme.labelSmall,
              ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/time.dart';

sealed class RescheduleChoice {
  const RescheduleChoice();
}

final class RescheduleQuickChoice extends RescheduleChoice {
  const RescheduleQuickChoice(this.date);

  final DateTime date;
}

final class ReschedulePickDateChoice extends RescheduleChoice {
  const ReschedulePickDateChoice();
}

Future<RescheduleChoice?> showRescheduleChoiceSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required DateTime dayKeyUtc,
}) async {
  DateTime nextWeekday(DateTime day, int weekday) {
    final normalized = dateOnly(day);
    final rawDelta = weekday - normalized.weekday;
    final delta = rawDelta <= 0 ? rawDelta + 7 : rawDelta;
    return normalized.add(Duration(days: delta));
  }

  final today = dateOnly(dayKeyUtc);
  final tomorrow = today.add(const Duration(days: 1));
  final thisWeekend = nextWeekday(today, DateTime.saturday);
  final nextWeek = nextWeekday(today, DateTime.monday);

  return showModalBottomSheet<RescheduleChoice>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(title),
              subtitle: Text(subtitle),
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: Text(l10n.dateTomorrow),
              onTap: () {
                Navigator.of(sheetContext).pop(
                  RescheduleQuickChoice(tomorrow),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.weekend_outlined),
              title: Text(l10n.dateThisWeekend),
              onTap: () {
                Navigator.of(sheetContext).pop(
                  RescheduleQuickChoice(thisWeekend),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(l10n.dateNextWeek),
              onTap: () {
                Navigator.of(sheetContext).pop(
                  RescheduleQuickChoice(nextWeek),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.pickDateLabel),
              onTap: () {
                Navigator.of(sheetContext).pop(
                  const ReschedulePickDateChoice(),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<DateTime?> showRescheduleDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
  );
  if (picked == null || !context.mounted) return null;
  return dateOnly(picked);
}

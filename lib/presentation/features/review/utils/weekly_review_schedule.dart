import 'package:taskly_domain/settings.dart';

DateTime _scheduledDateTimeForWeek({
  required DateTime nowLocal,
  required int dayOfWeek,
  required int minutesOfDay,
}) {
  final normalizedDay = DateTime(
    nowLocal.year,
    nowLocal.month,
    nowLocal.day,
  );

  final clampedDay = dayOfWeek.clamp(DateTime.monday, DateTime.sunday);
  final dayDelta = (clampedDay - normalizedDay.weekday) % 7;
  final scheduledDay = normalizedDay.add(Duration(days: dayDelta));

  final hours = (minutesOfDay ~/ 60).clamp(0, 23);
  final minutes = (minutesOfDay % 60).clamp(0, 59);

  return DateTime(
    scheduledDay.year,
    scheduledDay.month,
    scheduledDay.day,
    hours,
    minutes,
  );
}

bool isWeeklyReviewReady(GlobalSettings settings, DateTime nowLocal) {
  final scheduled = _scheduledDateTimeForWeek(
    nowLocal: nowLocal,
    dayOfWeek: settings.weeklyReviewDayOfWeek,
    minutesOfDay: settings.weeklyReviewTimeMinutes,
  );

  if (nowLocal.isBefore(scheduled)) return false;

  final lastCompleted = settings.weeklyReviewLastCompletedAt;
  if (lastCompleted == null) return true;

  final cadenceWeeks = settings.weeklyReviewCadenceWeeks.clamp(1, 2);
  final lastCompletedLocal = lastCompleted.toLocal();
  if (!lastCompletedLocal.isBefore(scheduled)) return false;

  final daysSinceCompletion = scheduled.difference(lastCompletedLocal).inDays;
  return daysSinceCompletion >= cadenceWeeks * 7;
}

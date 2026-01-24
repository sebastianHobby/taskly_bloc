import 'package:flutter/foundation.dart';

@immutable
class TaskSnoozeStats {
  const TaskSnoozeStats({
    required this.snoozeCount,
    required this.totalSnoozeDays,
  });

  final int snoozeCount;
  final int totalSnoozeDays;
}

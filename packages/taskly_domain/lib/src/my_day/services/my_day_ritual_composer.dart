import 'package:meta/meta.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/src/services/values/effective_values.dart';
import 'package:taskly_domain/time.dart';

@immutable
final class MyDayRitualComposition {
  const MyDayRitualComposition({
    required this.planned,
    required this.curated,
    required this.curatedReasonLineByTaskId,
    required this.curatedTooltipByTaskId,
    required this.curatedReasonCodesByTaskId,
  });

  final List<Task> planned;
  final List<Task> curated;
  final Map<String, String> curatedReasonLineByTaskId;
  final Map<String, String> curatedTooltipByTaskId;
  final Map<String, List<AllocationReasonCode>> curatedReasonCodesByTaskId;
}

/// Domain policy for composing the My Day ritual task lists.
///
/// This is intentionally UI-agnostic: it returns tasks plus lightweight
/// explanation strings for "why suggested".
@immutable
final class MyDayRitualComposer {
  const MyDayRitualComposer();

  MyDayRitualComposition compose({
    required List<Task> tasks,
    required DateTime dayKeyUtc,
    required int dueWindowDays,
    required bool includeDueSoon,
    required my_day.MyDayDayPicks dayPicks,
    required Set<String> selectedTaskIds,
    required AllocationResult? allocation,
  }) {
    final curated = _buildCurated(
      tasks: tasks,
      dayPicks: dayPicks,
      allocation: allocation,
      selectedTaskIds: selectedTaskIds,
    );
    final curatedIds = curated.map((t) => t.id).toSet();

    final planned = _buildPlanned(
      tasks,
      dayKeyUtc,
      dueWindowDays,
      includeDueSoon: includeDueSoon,
      excludeIds: {...selectedTaskIds, ...curatedIds},
    );

    final details = _buildCuratedReasonDetails(
      curated,
      allocation: allocation,
      dayKeyUtc: dayKeyUtc,
    );

    return MyDayRitualComposition(
      planned: planned,
      curated: curated,
      curatedReasonLineByTaskId: details.reasonLineByTaskId,
      curatedTooltipByTaskId: details.tooltipByTaskId,
      curatedReasonCodesByTaskId: details.reasonCodesByTaskId,
    );
  }

  List<Task> _buildPlanned(
    List<Task> tasks,
    DateTime dayKeyUtc,
    int dueWindowDays, {
    required bool includeDueSoon,
    required Set<String> excludeIds,
  }) {
    final today = dateOnly(dayKeyUtc);
    final dueSoonLimit = today.add(Duration(days: dueWindowDays - 1));

    bool isPlanned(Task task) {
      if (_isCompleted(task)) return false;
      if (excludeIds.contains(task.id)) return false;
      final start = dateOnlyOrNull(task.occurrence?.date ?? task.startDate);
      final deadline = dateOnlyOrNull(
        task.occurrence?.deadline ?? task.deadlineDate,
      );
      final startEligible = start != null && !start.isAfter(today);
      final dueSoon = includeDueSoon &&
          deadline != null &&
          !deadline.isAfter(dueSoonLimit);
      return startEligible || dueSoon;
    }

    return tasks.where(isPlanned).toList(growable: false);
  }

  List<Task> _buildCurated({
    required List<Task> tasks,
    required my_day.MyDayDayPicks dayPicks,
    required AllocationResult? allocation,
    required Set<String> selectedTaskIds,
  }) {
    final curated = <Task>[];

    final tasksById = {for (final task in tasks) task.id: task};

    // Always include already-picked tasks that are NOT part of the planned set
    // so "resume" shows the current plan even if allocation candidates change.
    for (final pick in dayPicks.picks) {
      final taskId = pick.taskId;
      if (!selectedTaskIds.contains(taskId)) continue;
      final task = tasksById[taskId];
      if (task == null) continue;
      if (_isCompleted(task)) continue;
      curated.add(task);
    }

    if (allocation == null) return curated;

    for (final entry in allocation.allocatedTasks) {
      final task = entry.task;
      if (curated.any((t) => t.id == task.id)) continue;
      if (_isCompleted(task)) continue;
      curated.add(task);
    }

    return curated;
  }

  ({
    Map<String, String> reasonLineByTaskId,
    Map<String, String> tooltipByTaskId,
    Map<String, List<AllocationReasonCode>> reasonCodesByTaskId,
  })
  _buildCuratedReasonDetails(
    List<Task> curated, {
    required AllocationResult? allocation,
    required DateTime dayKeyUtc,
  }) {
    if (allocation == null) {
      return (
        reasonLineByTaskId: const <String, String>{},
        tooltipByTaskId: const <String, String>{},
        reasonCodesByTaskId: const <String, List<AllocationReasonCode>>{},
      );
    }

    final reasonsByTaskId = <String, List<AllocationReasonCode>>{};
    for (final entry in allocation.allocatedTasks) {
      reasonsByTaskId[entry.task.id] = entry.reasonCodes;
    }

    final reasonLineByTaskId = <String, String>{};
    final tooltipByTaskId = <String, String>{};

    for (final task in curated) {
      final reasonCodes = reasonsByTaskId[task.id] ?? const [];
      final reasonLine = _reasonLineForTask(task, reasonCodes, dayKeyUtc);
      final tooltip = _reasonTooltipForTask(task, reasonCodes, dayKeyUtc);

      if (reasonLine.isNotEmpty) {
        reasonLineByTaskId[task.id] = reasonLine;
      }
      if (tooltip.isNotEmpty) {
        tooltipByTaskId[task.id] = tooltip;
      }
    }

    return (
      reasonLineByTaskId: reasonLineByTaskId,
      tooltipByTaskId: tooltipByTaskId,
      reasonCodesByTaskId: reasonsByTaskId,
    );
  }

  String _reasonLineForTask(
    Task task,
    List<AllocationReasonCode> reasonCodes,
    DateTime dayKeyUtc,
  ) {
    final whyNow = _whyNowToken(task, reasonCodes, dayKeyUtc);
    final whyItMatters = _whyItMattersToken(task, reasonCodes);

    if (whyNow.isEmpty && whyItMatters.isEmpty) return '';
    if (whyNow.isEmpty) return whyItMatters;
    if (whyItMatters.isEmpty) return whyNow;
    if (whyNow == whyItMatters) return whyNow;
    return '$whyNow · $whyItMatters';
  }

  String _whyNowToken(
    Task task,
    List<AllocationReasonCode> reasonCodes,
    DateTime dayKeyUtc,
  ) {
    if (reasonCodes.contains(AllocationReasonCode.urgency)) {
      return _deadlineLabel(task, dayKeyUtc);
    }

    if (reasonCodes.contains(AllocationReasonCode.neglectBalance)) {
      final primaryValueName = task.effectivePrimaryValue?.name.trim();
      if (primaryValueName != null && primaryValueName.isNotEmpty) {
        return 'Rebalancing toward $primaryValueName';
      }
      return 'Rebalancing';
    }

    if (reasonCodes.contains(AllocationReasonCode.priority)) {
      return 'Priority';
    }

    return 'Suggested';
  }

  String _whyItMattersToken(Task task, List<AllocationReasonCode> reasonCodes) {
    if (reasonCodes.contains(AllocationReasonCode.crossValue)) {
      return 'Cross-value';
    }

    if (reasonCodes.contains(AllocationReasonCode.neglectBalance)) {
      return '';
    }

    final primaryValueName = task.effectivePrimaryValue?.name.trim();
    if (primaryValueName != null && primaryValueName.isNotEmpty) {
      return primaryValueName;
    }

    if (reasonCodes.contains(AllocationReasonCode.neglectBalance)) {
      return 'Balance';
    }

    if (reasonCodes.contains(AllocationReasonCode.priority)) {
      return 'Priority';
    }

    return '';
  }

  String _reasonTooltipForTask(
    Task task,
    List<AllocationReasonCode> reasonCodes,
    DateTime dayKeyUtc,
  ) {
    if (reasonCodes.isEmpty && task.isEffectivelyValueless) return '';

    final bullets = <String>[];

    if (reasonCodes.contains(AllocationReasonCode.urgency)) {
      bullets.add(_deadlineLabel(task, dayKeyUtc));
    }

    if (reasonCodes.contains(AllocationReasonCode.priority)) {
      bullets.add('High priority');
    }

    if (reasonCodes.contains(AllocationReasonCode.neglectBalance)) {
      final primaryValueName = task.effectivePrimaryValue?.name.trim();
      if (primaryValueName != null && primaryValueName.isNotEmpty) {
        bullets.add('Rebalancing toward $primaryValueName');
      } else {
        bullets.add('Rebalancing');
      }
    }

    if (reasonCodes.contains(AllocationReasonCode.crossValue)) {
      final valueNames = task.effectiveValues
          .map((v) => v.name.trim())
          .where((n) => n.isNotEmpty)
          .toList(growable: false);

      if (valueNames.length >= 2) {
        bullets.add(
          'Cross-value: advances ${valueNames[0]} + ${valueNames[1]}',
        );
      } else {
        bullets.add('Cross-value');
      }
    } else {
      final primaryValueName = task.effectivePrimaryValue?.name.trim();
      if (primaryValueName != null && primaryValueName.isNotEmpty) {
        bullets.add('Supports $primaryValueName');
      }
    }

    if (bullets.isEmpty) return '';

    final buffer = StringBuffer('Why suggested');
    for (final item in bullets) {
      buffer.write('\n• $item');
    }
    return buffer.toString();
  }

  String _deadlineLabel(Task task, DateTime dayKeyUtc) {
    final deadline = dateOnlyOrNull(task.deadlineDate);
    if (deadline == null) return 'Due soon';

    final today = dateOnly(dayKeyUtc);
    final diff = deadline.difference(today).inDays;

    if (diff < 0) return 'Past due';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }

  bool _isCompleted(Task task) {
    return task.occurrence?.isCompleted ?? task.completed;
  }
}

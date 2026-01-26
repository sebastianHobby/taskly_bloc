import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

import '../../helpers/test_helpers.dart';

class _FakeMyDayRepository implements MyDayRepositoryContract {
  _FakeMyDayRepository(this._dayPicks)
    : _controller = StreamController.broadcast();

  MyDayDayPicks _dayPicks;
  final StreamController<MyDayDayPicks> _controller;

  void emit(MyDayDayPicks dayPicks) {
    _dayPicks = dayPicks;
    _controller.add(dayPicks);
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Stream<MyDayDayPicks> watchDay(DateTime dayKeyUtc) => _controller.stream;

  @override
  Future<MyDayDayPicks> loadDay(DateTime dayKeyUtc) async => _dayPicks;

  @override
  Future<void> setDayPicks({
    required DateTime dayKeyUtc,
    required DateTime ritualCompletedAtUtc,
    required List<MyDayPick> picks,
    required OperationContext context,
  }) async {
    emit(
      MyDayDayPicks(
        dayKeyUtc: dayKeyUtc,
        ritualCompletedAtUtc: ritualCompletedAtUtc,
        picks: picks,
      ),
    );
  }

  @override
  Future<void> appendPick({
    required DateTime dayKeyUtc,
    required String taskId,
    required MyDayPickBucket bucket,
    required OperationContext context,
  }) async {
    final updated = [
      ..._dayPicks.picks,
      MyDayPick.task(
        taskId: taskId,
        bucket: bucket,
        sortIndex: _dayPicks.picks.length,
        pickedAtUtc: DateTime.utc(2026, 1, 1),
      ),
    ];
    emit(
      MyDayDayPicks(
        dayKeyUtc: dayKeyUtc,
        ritualCompletedAtUtc: _dayPicks.ritualCompletedAtUtc,
        picks: updated,
      ),
    );
  }

  @override
  Future<void> clearDay({
    required DateTime dayKeyUtc,
    OperationContext? context,
  }) async {
    emit(
      MyDayDayPicks(
        dayKeyUtc: dayKeyUtc,
        ritualCompletedAtUtc: null,
        picks: const [],
      ),
    );
  }
}

void main() {
  testSafe('MyDayRitualStatus.fromDayPicks aggregates buckets', () async {
    final dayKey = DateTime.utc(2026, 1, 2);
    final dayPicks = MyDayDayPicks(
      dayKeyUtc: dayKey,
      ritualCompletedAtUtc: DateTime.utc(2026, 1, 2, 12),
      picks: [
        MyDayPick.task(
          taskId: 't1',
          bucket: MyDayPickBucket.valueSuggestions,
          sortIndex: 0,
          pickedAtUtc: DateTime.utc(2026, 1, 2, 8),
        ),
        MyDayPick.task(
          taskId: 't2',
          bucket: MyDayPickBucket.due,
          sortIndex: 1,
          pickedAtUtc: DateTime.utc(2026, 1, 2, 8),
        ),
        MyDayPick.routine(
          routineId: 'r1',
          bucket: MyDayPickBucket.routine,
          sortIndex: 2,
          pickedAtUtc: DateTime.utc(2026, 1, 2, 8),
        ),
      ],
    );

    final status = MyDayRitualStatus.fromDayPicks(dayPicks);

    expect(status.dayKeyUtc, dayKey);
    expect(status.hasAnyPick, isTrue);
    expect(status.totalPickCount, 3);
    expect(status.ritualCompletedAtUtc, dayPicks.ritualCompletedAtUtc);
    expect(status.countsByBucket[MyDayPickBucket.valueSuggestions], 1);
    expect(status.countsByBucket[MyDayPickBucket.due], 1);
    expect(status.countsByBucket[MyDayPickBucket.routine], 1);
  });

  testSafe('MyDayRitualStatusService maps loadDay into status', () async {
    final dayKey = DateTime.utc(2026, 1, 3);
    final repo = _FakeMyDayRepository(
      MyDayDayPicks(
        dayKeyUtc: dayKey,
        ritualCompletedAtUtc: null,
        picks: const [],
      ),
    );
    addTearDown(repo.dispose);

    final service = MyDayRitualStatusService(myDayRepository: repo);
    final status = await service.getStatus(dayKey);

    expect(status.dayKeyUtc, dayKey);
    expect(status.hasAnyPick, isFalse);
    expect(status.totalPickCount, 0);
    expect(status.countsByBucket, isEmpty);
  });

  testSafe('MyDayRitualStatusService.watchStatus emits updates', () async {
    final dayKey = DateTime.utc(2026, 1, 4);
    final repo = _FakeMyDayRepository(
      MyDayDayPicks(
        dayKeyUtc: dayKey,
        ritualCompletedAtUtc: null,
        picks: const [],
      ),
    );
    addTearDown(repo.dispose);

    final service = MyDayRitualStatusService(myDayRepository: repo);

    final stream = service.watchStatus(dayKey);
    final expectFuture = expectLater(
      stream,
      emitsInOrder([
        predicate<MyDayRitualStatus>((status) => !status.hasAnyPick),
        predicate<MyDayRitualStatus>((status) => status.totalPickCount == 1),
      ]),
    );

    repo.emit(
      MyDayDayPicks(
        dayKeyUtc: dayKey,
        ritualCompletedAtUtc: null,
        picks: const [],
      ),
    );
    repo.emit(
      MyDayDayPicks(
        dayKeyUtc: dayKey,
        ritualCompletedAtUtc: null,
        picks: [
          MyDayPick.task(
            taskId: 't1',
            bucket: MyDayPickBucket.manual,
            sortIndex: 0,
            pickedAtUtc: DateTime.utc(2026, 1, 4, 8),
          ),
        ],
      ),
    );

    await expectFuture;
  });
}

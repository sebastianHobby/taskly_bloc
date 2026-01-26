import 'package:taskly_domain/src/interfaces/my_day_repository_contract.dart';
import 'package:taskly_domain/src/my_day/model/my_day_day_picks.dart';
import 'package:taskly_domain/src/my_day/model/my_day_ritual_status.dart';

final class MyDayRitualStatusService {
  const MyDayRitualStatusService({
    required MyDayRepositoryContract myDayRepository,
  }) : _myDayRepository = myDayRepository;

  final MyDayRepositoryContract _myDayRepository;

  Future<MyDayRitualStatus> getStatus(DateTime dayKeyUtc) async {
    final dayPicks = await _myDayRepository.loadDay(dayKeyUtc);
    return MyDayRitualStatus.fromDayPicks(dayPicks);
  }

  Stream<MyDayRitualStatus> watchStatus(DateTime dayKeyUtc) {
    return _myDayRepository
        .watchDay(dayKeyUtc)
        .map(MyDayRitualStatus.fromDayPicks);
  }

  MyDayRitualStatus fromDayPicks(MyDayDayPicks dayPicks) {
    return MyDayRitualStatus.fromDayPicks(dayPicks);
  }
}

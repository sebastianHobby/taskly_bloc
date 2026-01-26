import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/my_day.dart' show MyDayRitualStatus;

import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/models/my_day_view_model_builder.dart';

final class MyDayQueryService {
  MyDayQueryService({
    required AllocationOrchestrator allocationOrchestrator,
    required TaskRepositoryContract taskRepository,
    required ValueRepositoryContract valueRepository,
    required MyDayRepositoryContract myDayRepository,
    required MyDayRitualStatusService ritualStatusService,
    required RoutineRepositoryContract routineRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
    MyDayViewModelBuilder viewModelBuilder = const MyDayViewModelBuilder(),
  }) : _allocationOrchestrator = allocationOrchestrator,
       _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       _myDayRepository = myDayRepository,
       _ritualStatusService = ritualStatusService,
       _routineRepository = routineRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       _viewModelBuilder = viewModelBuilder;

  final AllocationOrchestrator _allocationOrchestrator;
  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;
  final MyDayRepositoryContract _myDayRepository;
  final MyDayRitualStatusService _ritualStatusService;
  final RoutineRepositoryContract _routineRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final MyDayViewModelBuilder _viewModelBuilder;

  Stream<MyDayViewModel> watchMyDayViewModel() {
    final triggers = Rx.merge([
      Stream<void>.value(null),
      _temporalTriggerService.events
          .where((e) => e is HomeDayBoundaryCrossed || e is AppResumed)
          .map((_) => null),
    ]);

    return triggers
        .map((_) => _dayKeyService.todayDayKeyUtc())
        .distinct((a, b) => a.isAtSameMomentAs(b))
        .switchMap(_watchForDay);
  }

  Stream<MyDayViewModel> _watchForDay(DateTime dayKeyUtc) {
    // Important: `Stream.fromFuture(...)` creates a single-subscription stream.
    // This method uses `switchMap`, so the inner stream can be re-subscribed
    // multiple times as inputs change.
    // Keep the *Future* stable, but create a fresh Stream per subscription.
    final valuesFuture = _valueRepository.getAll();

    final dayPicks$ = Rx.concat([
      Stream.fromFuture(_myDayRepository.loadDay(dayKeyUtc)),
      _myDayRepository.watchDay(dayKeyUtc),
    ]);

    return dayPicks$.switchMap((dayPicks) {
      final ritualStatus = _ritualStatusService.fromDayPicks(dayPicks);
      if (dayPicks.ritualCompletedAtUtc != null) {
        final values$ = Stream.fromFuture(valuesFuture);

        final tasks$ = Rx.concat([
          Stream.fromFuture(_taskRepository.getAll(TaskQuery.all())),
          _taskRepository.watchAll(TaskQuery.all()),
        ]);

        final routines$ = Rx.concat([
          Stream.fromFuture(
            _routineRepository.getAll(includeInactive: true),
          ),
          _routineRepository.watchAll(includeInactive: true),
        ]);
        final completions$ = Rx.concat([
          Stream.fromFuture(_routineRepository.getCompletions()),
          _routineRepository.watchCompletions(),
        ]);
        final skips$ = Rx.concat([
          Stream.fromFuture(_routineRepository.getSkips()),
          _routineRepository.watchSkips(),
        ]);

        return Rx.combineLatest5<
          List<Task>,
          List<Value>,
          List<Routine>,
          List<RoutineCompletion>,
          List<RoutineSkip>,
          MyDayViewModel
        >(
          tasks$,
          values$,
          routines$,
          completions$,
          skips$,
          (tasks, values, routines, completions, skips) =>
              _viewModelBuilder.fromDailyPicks(
                dayPicks: dayPicks,
                ritualStatus: ritualStatus,
                tasks: tasks,
                values: values,
                routines: routines,
                routineCompletions: completions,
                routineSkips: skips,
              ),
        );
      }

      return Stream.fromFuture(
        _loadAllocationViewModel(ritualStatus: ritualStatus),
      );
    });
  }

  Future<MyDayViewModel> _loadAllocationViewModel({
    required MyDayRitualStatus ritualStatus,
  }) async {
    final results = await Future.wait([
      _allocationOrchestrator.getAllocationSnapshot(),
      _valueRepository.getAll(),
    ]);

    final allocation = results[0] as AllocationResult;
    final values = results[1] as List<Value>;

    return _viewModelBuilder.fromAllocation(
      allocation: allocation,
      values: values,
      ritualStatus: ritualStatus,
    );
  }
}

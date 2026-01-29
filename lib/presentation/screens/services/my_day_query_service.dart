import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';

import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/models/my_day_view_model_builder.dart';
import 'package:taskly_bloc/presentation/shared/session/session_allocation_cache_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';

final class MyDayQueryService {
  MyDayQueryService({
    required TaskRepositoryContract taskRepository,
    required MyDayRepositoryContract myDayRepository,
    required MyDayRitualStatusService ritualStatusService,
    required RoutineRepositoryContract routineRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
    required SessionAllocationCacheService allocationCacheService,
    required SessionSharedDataService sharedDataService,
    required DemoModeService demoModeService,
    required DemoDataProvider demoDataProvider,
    MyDayViewModelBuilder viewModelBuilder = const MyDayViewModelBuilder(),
  }) : _taskRepository = taskRepository,
       _myDayRepository = myDayRepository,
       _ritualStatusService = ritualStatusService,
       _routineRepository = routineRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       _allocationCacheService = allocationCacheService,
       _sharedDataService = sharedDataService,
       _demoModeService = demoModeService,
       _demoDataProvider = demoDataProvider,
       _viewModelBuilder = viewModelBuilder;

  final TaskRepositoryContract _taskRepository;
  final MyDayRepositoryContract _myDayRepository;
  final MyDayRitualStatusService _ritualStatusService;
  final RoutineRepositoryContract _routineRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final SessionAllocationCacheService _allocationCacheService;
  final SessionSharedDataService _sharedDataService;
  final DemoModeService _demoModeService;
  final DemoDataProvider _demoDataProvider;
  final MyDayViewModelBuilder _viewModelBuilder;

  Stream<MyDayViewModel> watchMyDayViewModel() {
    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        return Stream<MyDayViewModel>.value(
          _demoDataProvider.buildMyDayViewModel(),
        );
      }
      return _watchMyDayViewModel();
    });
  }

  Stream<MyDayViewModel> _watchMyDayViewModel() {
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
    final values$ = _sharedDataService.watchValues();

    final dayPicks$ = Rx.concat([
      Stream.fromFuture(_myDayRepository.loadDay(dayKeyUtc)),
      _myDayRepository.watchDay(dayKeyUtc),
    ]);

    return dayPicks$.switchMap((dayPicks) {
      final ritualStatus = _ritualStatusService.fromDayPicks(dayPicks);
      if (dayPicks.ritualCompletedAtUtc != null) {
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

      final allocation$ = _allocationCacheService.watchAllocationSnapshot();

      return Rx.combineLatest2<AllocationResult, List<Value>, MyDayViewModel>(
        allocation$,
        values$,
        (allocation, values) => _viewModelBuilder.fromAllocation(
          allocation: allocation,
          values: values,
          ritualStatus: ritualStatus,
        ),
      );
    });
  }
}

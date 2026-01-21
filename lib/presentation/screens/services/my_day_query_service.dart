import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart' as settings;

import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/models/my_day_view_model_builder.dart';

final class MyDayQueryService {
  MyDayQueryService({
    required AllocationOrchestrator allocationOrchestrator,
    required TaskRepositoryContract taskRepository,
    required ValueRepositoryContract valueRepository,
    required SettingsRepositoryContract settingsRepository,
    required MyDayRepositoryContract myDayRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
    MyDayViewModelBuilder viewModelBuilder = const MyDayViewModelBuilder(),
  }) : _allocationOrchestrator = allocationOrchestrator,
       _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       _settingsRepository = settingsRepository,
       _myDayRepository = myDayRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       _viewModelBuilder = viewModelBuilder;

  final AllocationOrchestrator _allocationOrchestrator;
  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;
  final SettingsRepositoryContract _settingsRepository;
  final MyDayRepositoryContract _myDayRepository;
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
    final globalFuture = _settingsRepository.load<settings.GlobalSettings>(
      SettingsKey.global,
    );

    final dayPicks$ = Rx.concat([
      Stream.fromFuture(_myDayRepository.loadDay(dayKeyUtc)),
      _myDayRepository.watchDay(dayKeyUtc),
    ]);

    return dayPicks$.switchMap((dayPicks) {
      if (dayPicks.ritualCompletedAtUtc != null) {
        final values$ = Stream.fromFuture(valuesFuture);
        final global$ = Stream.fromFuture(globalFuture);

        final tasks$ = Rx.concat([
          Stream.fromFuture(_taskRepository.getAll(TaskQuery.incomplete())),
          _taskRepository.watchAll(TaskQuery.incomplete()),
        ]);

        return Rx.combineLatest3<
          List<Task>,
          List<Value>,
          settings.GlobalSettings,
          MyDayViewModel
        >(
          tasks$,
          values$,
          global$,
          (tasks, values, global) => _viewModelBuilder.fromDailyPicks(
            dayPicks: dayPicks,
            dayKeyUtc: dayKeyUtc,
            tasks: tasks,
            values: values,
            globalSettings: global,
          ),
        );
      }

      return Stream.fromFuture(_loadAllocationViewModel());
    });
  }

  Future<MyDayViewModel> _loadAllocationViewModel() async {
    final results = await Future.wait([
      _allocationOrchestrator.getAllocationSnapshot(),
      _valueRepository.getAll(),
    ]);

    final allocation = results[0] as AllocationResult;
    final values = results[1] as List<Value>;

    return _viewModelBuilder.fromAllocation(
      allocation: allocation,
      values: values,
    );
  }
}

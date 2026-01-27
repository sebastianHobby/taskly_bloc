import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/mixins/list_bloc_mixin.dart';
import 'package:taskly_bloc/presentation/shared/utils/sort_utils.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

part 'value_list_bloc.freezed.dart';

@freezed
sealed class ValueListEvent with _$ValueListEvent {
  const factory ValueListEvent.subscriptionRequested() =
      ValueListSubscriptionRequested;
  const factory ValueListEvent.sortChanged({
    required SortPreferences preferences,
  }) = ValueListSortChanged;
  const factory ValueListEvent.deleteValue({
    required Value value,
  }) = ValueListDeleteValue;
}

@freezed
sealed class ValueListState with _$ValueListState {
  const factory ValueListState.initial() = ValueListInitial;
  const factory ValueListState.loading() = ValueListLoading;
  const factory ValueListState.loaded({required List<Value> values}) =
      ValueListLoaded;
  const factory ValueListState.error({
    required Object error,
    StackTrace? stackTrace,
  }) = ValueListError;
}

class ValueListBloc extends Bloc<ValueListEvent, ValueListState>
    with ListBlocMixin<ValueListEvent, ValueListState, Value> {
  ValueListBloc({
    required ValueRepositoryContract valueRepository,
    required ValueWriteService valueWriteService,
    required AppErrorReporter errorReporter,
    SettingsRepositoryContract? settingsRepository,
    PageKey? pageKey,
    SortPreferences initialSortPreferences = const SortPreferences(
      criteria: [SortCriterion(field: SortField.name)],
    ),
  }) : _valueRepository = valueRepository,
       _valueWriteService = valueWriteService,
       _errorReporter = errorReporter,
       _settingsRepository = settingsRepository,
       _pageKey = pageKey,
       _sortPreferences = initialSortPreferences,
       super(const ValueListInitial()) {
    on<ValueListSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<ValueListSortChanged>(_onSortChanged, transformer: restartable());
    on<ValueListDeleteValue>(_onDeleteValue, transformer: droppable());
  }

  final ValueRepositoryContract _valueRepository;
  final ValueWriteService _valueWriteService;
  final AppErrorReporter _errorReporter;
  final SettingsRepositoryContract? _settingsRepository;
  final PageKey? _pageKey;
  SortPreferences _sortPreferences;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  void _reportIfUnexpectedOrUnmapped(
    Object error,
    StackTrace stackTrace, {
    required OperationContext context,
    required String message,
  }) {
    if (error is AppFailure && error.reportAsUnexpected) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unexpected failure)',
      );
      return;
    }

    if (error is! AppFailure) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unmapped exception)',
      );
    }
  }

  OperationContext _newContext({
    required String intent,
    required String operation,
    String? entityId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'values',
      screen: 'value_list',
      intent: intent,
      operation: operation,
      entityType: 'value',
      entityId: entityId,
      extraFields: extraFields,
    );
  }

  SortPreferences get currentSortPreferences => _sortPreferences;

  // ListBlocMixin implementation
  @override
  ValueListState createLoadingState() => const ValueListLoading();

  @override
  ValueListState createErrorState(Object error, [StackTrace? stackTrace]) =>
      ValueListError(error: error, stackTrace: stackTrace);

  @override
  ValueListState createLoadedState(List<Value> items) =>
      ValueListLoaded(values: items);

  List<Value> _sortValues(List<Value> values) {
    final criteria = _sortPreferences.sanitizedCriteria(const [SortField.name]);
    final direction = criteria.first.direction;
    final modifier = direction == SortDirection.ascending ? 1 : -1;
    final sorted = [...values];
    sorted.sort((a, b) => modifier * compareAsciiLowerCase(a.name, b.name));
    return sorted;
  }

  @override
  Future<void> close() {
    // emit.forEach subscriptions are automatically cancelled by framework
    return super.close();
  }

  Future<void> _onSubscriptionRequested(
    ValueListSubscriptionRequested event,
    Emitter<ValueListState> emit,
  ) async {
    AppLog.warnThrottledStructured(
      'values.list.subscribe',
      const Duration(seconds: 2),
      'values.list',
      'subscription requested',
      fields: <String, Object?>{
        'pageKey': _pageKey?.toString(),
        'sort': _sortPreferences.criteria.map((c) => c.field.name).join(','),
      },
    );

    // Load sort preferences from adapter if available
    if (_settingsRepository != null && _pageKey != null) {
      final savedSort = await _settingsRepository.load(
        SettingsKey.pageSort(_pageKey),
      );
      if (savedSort != null) {
        _sortPreferences = savedSort;
      }
    }

    // Ensure we always leave the loading state even if the watch stream takes
    // time to emit its first value (or never emits due to an upstream issue).
    emit(createLoadingState());
    try {
      final initialValues = await _valueRepository.getAll();
      AppLog.warnThrottledStructured(
        'values.list.initial',
        const Duration(seconds: 2),
        'values.list',
        'initial getAll',
        fields: <String, Object?>{'count': initialValues.length},
      );
      emit(createLoadedState(_sortValues(initialValues)));
    } catch (error, stackTrace) {
      emit(createErrorState(error, stackTrace));
      return;
    }

    final stream = _valueRepository.watchAll();

    await emit.forEach<List<Value>>(
      stream,
      onData: (values) {
        AppLog.warnThrottledStructured(
          'values.list.watchAll',
          const Duration(seconds: 2),
          'values.list',
          'watchAll emission',
          fields: <String, Object?>{'count': values.length},
        );
        return createLoadedState(_sortValues(values));
      },
      onError: createErrorState,
    );
  }

  Future<void> _onSortChanged(
    ValueListSortChanged event,
    Emitter<ValueListState> emit,
  ) async {
    _sortPreferences = event.preferences;
    state.maybeWhen(
      loaded: (values) => emit(ValueListLoaded(values: _sortValues(values))),
      orElse: () {},
    );

    // Persist to settings
    if (_settingsRepository != null && _pageKey != null) {
      final context = _contextFactory.create(
        feature: 'values',
        screen: 'value_list',
        intent: 'values_sort_preferences_changed',
        operation: 'settings.save.pageSort',
        extraFields: <String, Object?>{
          'pageKey': _pageKey.toString(),
        },
      );
      try {
        await _settingsRepository.save(
          SettingsKey.pageSort(_pageKey),
          event.preferences,
          context: context,
        );
      } catch (error, stackTrace) {
        _reportIfUnexpectedOrUnmapped(
          error,
          stackTrace,
          context: context,
          message: '[ValueListBloc] sort preferences persist failed',
        );
      }
    }
  }

  Future<void> _onDeleteValue(
    ValueListDeleteValue event,
    Emitter<ValueListState> emit,
  ) async {
    final context = _newContext(
      intent: 'value_delete_requested',
      operation: 'values.delete',
      entityId: event.value.id,
    );
    await executeDelete(
      emit,
      delete: () async {
        try {
          await _valueWriteService.delete(event.value.id, context: context);
        } catch (error, stackTrace) {
          _reportIfUnexpectedOrUnmapped(
            error,
            stackTrace,
            context: context,
            message: '[ValueListBloc] delete failed',
          );
          rethrow;
        }
      },
    );
  }
}

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/presentation/shared/mixins/list_bloc_mixin.dart';
import 'package:taskly_bloc/presentation/shared/utils/sort_utils.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';

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
    SettingsRepositoryContract? settingsRepository,
    PageKey? pageKey,
    SortPreferences initialSortPreferences = const SortPreferences(
      criteria: [SortCriterion(field: SortField.name)],
    ),
  }) : _valueRepository = valueRepository,
       _settingsRepository = settingsRepository,
       _pageKey = pageKey,
       _sortPreferences = initialSortPreferences,
       super(const ValueListInitial()) {
    on<ValueListSubscriptionRequested>(_onSubscriptionRequested);
    on<ValueListSortChanged>(_onSortChanged);
    on<ValueListDeleteValue>(_onDeleteValue);
  }

  final ValueRepositoryContract _valueRepository;
  final SettingsRepositoryContract? _settingsRepository;
  final PageKey? _pageKey;
  SortPreferences _sortPreferences;

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
    // Load sort preferences from adapter if available
    if (_settingsRepository != null && _pageKey != null) {
      final savedSort = await _settingsRepository.load(
        SettingsKey.pageSort(_pageKey),
      );
      if (savedSort != null) {
        _sortPreferences = savedSort;
      }
    }

    final stream = _valueRepository.watchAll();

    await subscribeToStream(emit, stream: stream, onData: _sortValues);
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
      await _settingsRepository.save(
        SettingsKey.pageSort(_pageKey),
        event.preferences,
      );
    }
  }

  Future<void> _onDeleteValue(
    ValueListDeleteValue event,
    Emitter<ValueListState> emit,
  ) async {
    await executeDelete(
      emit,
      delete: () => _valueRepository.delete(event.value.id),
    );
  }
}

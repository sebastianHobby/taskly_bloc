import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/mixins/list_bloc_mixin.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/utils/sort_utils.dart';
import 'package:taskly_bloc/data/adapters/page_sort_adapter.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';

part 'label_list_bloc.freezed.dart';

@freezed
sealed class LabelOverviewEvent with _$LabelOverviewEvent {
  const factory LabelOverviewEvent.subscriptionRequested() =
      LabelOverviewSubscriptionRequested;
  const factory LabelOverviewEvent.sortChanged({
    required SortPreferences preferences,
  }) = LabelsSortChanged;
  const factory LabelOverviewEvent.deleteLabel({
    required Label label,
  }) = LabelOverviewDeleteLabel;
}

@freezed
sealed class LabelOverviewState with _$LabelOverviewState {
  const factory LabelOverviewState.initial() = LabelOverviewInitial;
  const factory LabelOverviewState.loading() = LabelOverviewLoading;
  const factory LabelOverviewState.loaded({required List<Label> labels}) =
      LabelOverviewLoaded;
  const factory LabelOverviewState.error({required Object error}) =
      LabelOverviewError;
}

class LabelOverviewBloc extends Bloc<LabelOverviewEvent, LabelOverviewState>
    with ListBlocMixin<LabelOverviewEvent, LabelOverviewState, Label> {
  LabelOverviewBloc({
    required LabelRepositoryContract labelRepository,
    PageSortAdapter? sortAdapter,
    LabelType? typeFilter,
    SortPreferences initialSortPreferences = const SortPreferences(
      criteria: [SortCriterion(field: SortField.name)],
    ),
  }) : _labelRepository = labelRepository,
       _sortAdapter = sortAdapter,
       _typeFilter = typeFilter,
       _sortPreferences = initialSortPreferences,
       super(const LabelOverviewInitial()) {
    on<LabelOverviewSubscriptionRequested>(_onSubscriptionRequested);
    on<LabelsSortChanged>(_onSortChanged);
    on<LabelOverviewDeleteLabel>(_onDeleteLabel);
  }

  final LabelRepositoryContract _labelRepository;
  final PageSortAdapter? _sortAdapter;
  final LabelType? _typeFilter;
  SortPreferences _sortPreferences;

  SortPreferences get currentSortPreferences => _sortPreferences;

  // ListBlocMixin implementation
  @override
  LabelOverviewState createLoadingState() => const LabelOverviewLoading();

  @override
  LabelOverviewState createErrorState(Object error) =>
      LabelOverviewError(error: error);

  @override
  LabelOverviewState createLoadedState(List<Label> items) =>
      LabelOverviewLoaded(labels: items);

  List<Label> _sortLabels(List<Label> labels) {
    final criteria = _sortPreferences.sanitizedCriteria(const [SortField.name]);
    final direction = criteria.first.direction;
    final modifier = direction == SortDirection.ascending ? 1 : -1;
    final sorted = [...labels];
    sorted.sort((a, b) => modifier * compareAsciiLowerCase(a.name, b.name));
    return sorted;
  }

  @override
  Future<void> close() {
    // emit.forEach subscriptions are automatically cancelled by framework
    return super.close();
  }

  Future<void> _onSubscriptionRequested(
    LabelOverviewSubscriptionRequested event,
    Emitter<LabelOverviewState> emit,
  ) async {
    // Load sort preferences from adapter if available
    if (_sortAdapter != null) {
      final savedSort = await _sortAdapter.load();
      if (savedSort != null) {
        _sortPreferences = savedSort;
      }
    }

    final stream = _typeFilter == null
        ? _labelRepository.watchAll()
        : _labelRepository.watchByType(_typeFilter);

    await subscribeToStream(emit, stream: stream, onData: _sortLabels);
  }

  Future<void> _onSortChanged(
    LabelsSortChanged event,
    Emitter<LabelOverviewState> emit,
  ) async {
    _sortPreferences = event.preferences;
    state.maybeWhen(
      loaded: (labels) =>
          emit(LabelOverviewLoaded(labels: _sortLabels(labels))),
      orElse: () {},
    );

    // Persist to settings
    await _sortAdapter?.save(event.preferences);
  }

  Future<void> _onDeleteLabel(
    LabelOverviewDeleteLabel event,
    Emitter<LabelOverviewState> emit,
  ) async {
    await executeDelete(
      emit,
      delete: () => _labelRepository.delete(event.label.id),
    );
  }
}

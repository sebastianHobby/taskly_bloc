import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/utils/sort_utils.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';

part 'label_list_bloc.freezed.dart';

@freezed
sealed class LabelOverviewEvent with _$LabelOverviewEvent {
  const factory LabelOverviewEvent.labelsSubscriptionRequested() =
      LabelsSubscriptionRequested;
  const factory LabelOverviewEvent.sortChanged({
    required SortPreferences preferences,
  }) = LabelsSortChanged;
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

class LabelOverviewBloc extends Bloc<LabelOverviewEvent, LabelOverviewState> {
  LabelOverviewBloc({
    required LabelRepositoryContract labelRepository,
    LabelType? typeFilter,
    SortPreferences initialSortPreferences = const SortPreferences(
      criteria: [SortCriterion(field: SortField.name)],
    ),
  }) : _labelRepository = labelRepository,
       _typeFilter = typeFilter,
       _sortPreferences = initialSortPreferences,
       super(const LabelOverviewInitial()) {
    on<LabelsSubscriptionRequested>(_onSubscriptionRequested);
    on<LabelsSortChanged>(_onSortChanged);
  }

  final LabelRepositoryContract _labelRepository;
  final LabelType? _typeFilter;
  SortPreferences _sortPreferences;

  SortPreferences get currentSortPreferences => _sortPreferences;

  List<Label> _sortLabels(List<Label> labels) {
    final criteria = _sortPreferences.sanitizedCriteria(const [SortField.name]);
    final direction = criteria.first.direction;
    final modifier = direction == SortDirection.ascending ? 1 : -1;
    final sorted = [...labels];
    sorted.sort(
      (a, b) => modifier * compareAsciiLowerCase(a.name, b.name),
    );
    return sorted;
  }

  Future<void> _onSubscriptionRequested(
    LabelsSubscriptionRequested event,
    Emitter<LabelOverviewState> emit,
  ) async {
    emit(const LabelOverviewLoading());

    final stream = _typeFilter == null
        ? _labelRepository.watchAll()
        : _labelRepository.watchByType(_typeFilter);

    await emit.forEach<List<Label>>(
      stream,
      onData: (labels) => LabelOverviewLoaded(labels: _sortLabels(labels)),
      onError: (error, stack) => LabelOverviewError(error: error),
    );
  }

  void _onSortChanged(
    LabelsSortChanged event,
    Emitter<LabelOverviewState> emit,
  ) {
    _sortPreferences = event.preferences;
    state.maybeWhen(
      loaded: (labels) =>
          emit(LabelOverviewLoaded(labels: _sortLabels(labels))),
      orElse: () {},
    );
  }
}

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';

part 'label_list_bloc.freezed.dart';

@freezed
sealed class LabelOverviewEvent with _$LabelOverviewEvent {
  const factory LabelOverviewEvent.labelsSubscriptionRequested() =
      LabelsSubscriptionRequested;
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
  LabelOverviewBloc({required LabelRepositoryContract labelRepository})
    : _labelRepository = labelRepository,
      super(const LabelOverviewInitial()) {
    on<LabelsSubscriptionRequested>(_onSubscriptionRequested);
  }

  final LabelRepositoryContract _labelRepository;

  Future<void> _onSubscriptionRequested(
    LabelsSubscriptionRequested event,
    Emitter<LabelOverviewState> emit,
  ) async {
    emit(const LabelOverviewLoading());
    await emit.forEach<List<Label>>(
      _labelRepository.watchAll(),
      onData: (labels) => LabelOverviewLoaded(labels: labels),
      onError: (error, stack) => LabelOverviewError(error: error),
    );
  }
}

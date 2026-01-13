import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/analytics/model/correlation_result.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/analytics/model/trend_data.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';

part 'journal_dashboard_bloc.freezed.dart';

@freezed
abstract class JournalDashboardEvent with _$JournalDashboardEvent {
  const factory JournalDashboardEvent.load({
    required DateRange dateRange,
  }) = _Load;
}

@freezed
abstract class JournalDashboardState with _$JournalDashboardState {
  const factory JournalDashboardState({
    @Default(true) bool isLoading,
    TrendData? moodTrend,
    List<CorrelationResult>? topCorrelations,
    String? error,
  }) = _JournalDashboardState;
}

class JournalDashboardBloc
    extends Bloc<JournalDashboardEvent, JournalDashboardState> {
  JournalDashboardBloc(this._analyticsService)
    : super(const JournalDashboardState()) {
    on<_Load>(_onLoad, transformer: restartable());

    add(
      JournalDashboardEvent.load(
        dateRange: DateRange.last30Days(),
      ),
    );
  }

  final AnalyticsService _analyticsService;

  Future<void> _onLoad(_Load event, Emitter emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final moodTrend = await _analyticsService.getMoodTrend(
        range: event.dateRange,
      );

      final topCorrelations = await _analyticsService.getTopMoodCorrelations(
        range: event.dateRange,
        limit: 5,
      );

      emit(
        state.copyWith(
          isLoading: false,
          moodTrend: moodTrend,
          topCorrelations: topCorrelations,
        ),
      );
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to load journal dashboard');
      emit(
        state.copyWith(
          isLoading: false,
          error: friendlyErrorMessage(e),
        ),
      );
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_result.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/analytics/trend_data.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';

part 'wellbeing_dashboard_bloc.freezed.dart';

// Events
@freezed
abstract class WellbeingDashboardEvent with _$WellbeingDashboardEvent {
  const factory WellbeingDashboardEvent.load({
    required DateRange dateRange,
  }) = _Load;
}

// State
@freezed
abstract class WellbeingDashboardState with _$WellbeingDashboardState {
  const factory WellbeingDashboardState({
    @Default(true) bool isLoading,
    TrendData? moodTrend,
    List<CorrelationResult>? topCorrelations,
    String? error,
  }) = _WellbeingDashboardState;
}

// BLoC
class WellbeingDashboardBloc
    extends Bloc<WellbeingDashboardEvent, WellbeingDashboardState> {
  WellbeingDashboardBloc(this._analyticsService)
    : super(const WellbeingDashboardState()) {
    on<_Load>(_onLoad);

    // Automatically load dashboard data on initialization
    add(
      WellbeingDashboardEvent.load(
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
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }
}

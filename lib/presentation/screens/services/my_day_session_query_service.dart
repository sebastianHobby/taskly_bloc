import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';

final class MyDaySessionQueryService {
  MyDaySessionQueryService({
    required MyDayQueryService queryService,
    required SessionStreamCacheManager cacheManager,
  }) : _queryService = queryService,
       _cacheManager = cacheManager;

  final MyDayQueryService _queryService;
  final SessionStreamCacheManager _cacheManager;

  static const Object _cacheKey = 'session.my_day.view_model';

  ValueStream<MyDayViewModel> get viewModel =>
      _cacheManager.getOrCreate<MyDayViewModel>(
        key: _cacheKey,
        source: _queryService.watchMyDayViewModel,
        pauseOnBackground: true,
      );

  void start() {
    _cacheManager.preload<MyDayViewModel>(
      key: _cacheKey,
      source: _queryService.watchMyDayViewModel,
      pauseOnBackground: true,
    );
  }

  Future<void> stop() => _cacheManager.evict(_cacheKey);
}

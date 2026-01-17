import 'dart:async';

import 'package:logging/logging.dart';
import '../../attention/contracts/attention_engine_contract.dart';
import '../../attention/model/attention_item.dart';
import '../../attention/model/attention_rule.dart';
import '../../attention/model/attention_resolution.dart';
import '../../attention/query/attention_query.dart';

/// Starts a small set of common attention queries at boot so the first
/// navigation to Inbox/banners can render immediately.
///
/// This keeps subscriptions alive for the app lifetime.
class AttentionPrewarmService {
  AttentionPrewarmService({required AttentionEngineContract engine})
    : _engine = engine;

  final AttentionEngineContract _engine;

  final _log = Logger('AttentionPrewarmService');

  final List<StreamSubscription<List<AttentionItem>>> _subs = [];
  var _started = false;

  void start() {
    if (_started) return;
    _started = true;

    scheduleMicrotask(() {
      _log.fine('Starting attention prewarm');

      _subscribe(const AttentionQuery(buckets: {AttentionBucket.action}));
      _subscribe(const AttentionQuery(buckets: {AttentionBucket.review}));

      // Banner queries used by system screens.
      _subscribe(
        const AttentionQuery(
          buckets: {AttentionBucket.action, AttentionBucket.review},
        ),
      );
      _subscribe(
        AttentionQuery(
          buckets: {AttentionBucket.action, AttentionBucket.review},
          entityTypes: {AttentionEntityType.task},
        ),
      );
    });
  }

  void _subscribe(AttentionQuery query) {
    _subs.add(
      _engine
          .watch(query)
          .listen(
            (_) {},
            onError: (Object e, StackTrace s) {
              _log.warning('Prewarm query failed: $e', e, s);
            },
          ),
    );
  }

  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }
}

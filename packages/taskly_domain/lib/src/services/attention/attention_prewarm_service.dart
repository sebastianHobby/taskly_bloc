import 'dart:async';

import 'package:logging/logging.dart';
import 'package:taskly_domain/src/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_domain/src/attention/model/attention_item.dart';
import 'package:taskly_domain/src/attention/model/attention_rule.dart';
import 'package:taskly_domain/src/attention/model/attention_resolution.dart';
import 'package:taskly_domain/src/attention/query/attention_query.dart';

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

  Future<void> stop() async {
    if (!_started) return;
    _started = false;

    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
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
    await stop();
  }
}

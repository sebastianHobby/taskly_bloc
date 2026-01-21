import 'package:taskly_domain/src/attention/model/attention_item.dart';
import 'package:taskly_domain/src/attention/query/attention_query.dart';

abstract class AttentionEngineContract {
  /// Watches attention items for the given [query].
  ///
  /// Stream contract:
  /// - broadcast: implementation-defined (callers must not assume shareability
  ///   unless documented by the implementation/decorator)
  /// - replay: implementation-defined
  /// - cold/hot: typically **cold** per call, unless wrapped by a caching/
  ///   sharing decorator.
  Stream<List<AttentionItem>> watch(AttentionQuery query);
}

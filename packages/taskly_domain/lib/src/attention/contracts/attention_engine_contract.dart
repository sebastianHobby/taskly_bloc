import 'package:taskly_domain/src/attention/model/attention_item.dart';
import 'package:taskly_domain/src/attention/query/attention_query.dart';

abstract class AttentionEngineContract {
  Stream<List<AttentionItem>> watch(AttentionQuery query);
}

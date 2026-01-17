import '../model/attention_item.dart';
import '../query/attention_query.dart';

abstract class AttentionEngineContract {
  Stream<List<AttentionItem>> watch(AttentionQuery query);
}

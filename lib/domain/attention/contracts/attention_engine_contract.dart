import 'package:taskly_bloc/domain/attention/model/attention_item.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';

abstract class AttentionEngineContract {
  Stream<List<AttentionItem>> watch(AttentionQuery query);
}

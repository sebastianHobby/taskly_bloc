import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';

part 'attention_item.freezed.dart';
part 'attention_item.g.dart';

@freezed
abstract class AttentionItem with _$AttentionItem {
  const factory AttentionItem({
    required String id,
    required String ruleId,
    required String ruleKey,
    required AttentionRuleType ruleType,
    required String entityId,
    required AttentionEntityType entityType,
    required AttentionSeverity severity,
    required String title,
    required String description,
    required List<AttentionResolutionAction> availableActions,
    required DateTime detectedAt,
    Map<String, dynamic>? metadata,
  }) = _AttentionItem;

  factory AttentionItem.fromJson(Map<String, dynamic> json) =>
      _$AttentionItemFromJson(json);
}

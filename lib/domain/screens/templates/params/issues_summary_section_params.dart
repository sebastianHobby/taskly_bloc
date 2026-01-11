import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_tile_variants.dart';

part 'issues_summary_section_params.freezed.dart';
part 'issues_summary_section_params.g.dart';

/// Params for the issues summary template.
///
/// Displays attention issues across selected entity types.
@freezed
abstract class IssuesSummarySectionParams with _$IssuesSummarySectionParams {
  const factory IssuesSummarySectionParams({
    required AttentionItemTileVariant attentionItemTileVariant,

    /// Restrict issues to these entity types (e.g. ['task', 'project']).
    ///
    /// When null or empty, includes all supported entity types.
    List<String>? entityTypes,

    /// Minimum severity to include (e.g. 'critical', 'warning', 'info').
    ///
    /// When null, includes all severities.
    String? minSeverity,
  }) = _IssuesSummarySectionParams;

  factory IssuesSummarySectionParams.fromJson(Map<String, dynamic> json) =>
      _$IssuesSummarySectionParamsFromJson(json);
}

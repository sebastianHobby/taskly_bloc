import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';

part 'attention_inbox_section_params_v1.freezed.dart';
part 'attention_inbox_section_params_v1.g.dart';

/// Params for the unified Attention Inbox section.
///
/// This is the section-based (USM) version of the legacy full-screen inbox.
@freezed
abstract class AttentionInboxSectionParamsV1
    with _$AttentionInboxSectionParamsV1 {
  const factory AttentionInboxSectionParamsV1({
    required StylePackV2 pack,
  }) = _AttentionInboxSectionParamsV1;

  factory AttentionInboxSectionParamsV1.fromJson(Map<String, dynamic> json) =>
      _$AttentionInboxSectionParamsV1FromJson(json);
}

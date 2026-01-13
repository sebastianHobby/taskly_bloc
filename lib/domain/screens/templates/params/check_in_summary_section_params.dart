import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';

part 'check_in_summary_section_params.freezed.dart';
part 'check_in_summary_section_params.g.dart';

/// Params for the check-in summary template.
@freezed
abstract class CheckInSummarySectionParams with _$CheckInSummarySectionParams {
  const factory CheckInSummarySectionParams({
    required StylePackV2 pack,
  }) = _CheckInSummarySectionParams;

  factory CheckInSummarySectionParams.fromJson(Map<String, dynamic> json) =>
      _$CheckInSummarySectionParamsFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_tile_variants.dart';

part 'check_in_summary_section_params.freezed.dart';
part 'check_in_summary_section_params.g.dart';

/// Params for the check-in summary template.
@freezed
abstract class CheckInSummarySectionParams with _$CheckInSummarySectionParams {
  const factory CheckInSummarySectionParams({
    required ReviewItemTileVariant reviewItemTileVariant,
  }) = _CheckInSummarySectionParams;

  factory CheckInSummarySectionParams.fromJson(Map<String, dynamic> json) =>
      _$CheckInSummarySectionParamsFromJson(json);
}

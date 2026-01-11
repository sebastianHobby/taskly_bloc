import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_tile_variants.dart';

part 'allocation_alerts_section_params.freezed.dart';
part 'allocation_alerts_section_params.g.dart';

/// Params for the allocation alerts template.
@freezed
abstract class AllocationAlertsSectionParams
    with _$AllocationAlertsSectionParams {
  const factory AllocationAlertsSectionParams({
    required AttentionItemTileVariant attentionItemTileVariant,
  }) = _AllocationAlertsSectionParams;

  factory AllocationAlertsSectionParams.fromJson(Map<String, dynamic> json) =>
      _$AllocationAlertsSectionParamsFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';

part 'allocation_alerts_section_params.freezed.dart';
part 'allocation_alerts_section_params.g.dart';

/// Params for the allocation alerts template.
@freezed
abstract class AllocationAlertsSectionParams
    with _$AllocationAlertsSectionParams {
  const factory AllocationAlertsSectionParams({
    required StylePackV2 pack,
  }) = _AllocationAlertsSectionParams;

  factory AllocationAlertsSectionParams.fromJson(Map<String, dynamic> json) =>
      _$AllocationAlertsSectionParamsFromJson(json);
}

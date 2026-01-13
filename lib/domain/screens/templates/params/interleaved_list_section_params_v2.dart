import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';

part 'interleaved_list_section_params_v2.freezed.dart';
part 'interleaved_list_section_params_v2.g.dart';

/// Params for the V2 interleaved list template.
///
/// Unlike the legacy model, V2 uses a list of `DataConfig` sources and a single
/// shared tiles/layout/enrichment policy.
@freezed
abstract class InterleavedListSectionParamsV2
    with _$InterleavedListSectionParamsV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory InterleavedListSectionParamsV2({
    required List<DataConfig> sources,
    required StylePackV2 pack,
    required SectionLayoutSpecV2 layout,
    @Default(EnrichmentPlanV2()) EnrichmentPlanV2 enrichment,
    SectionFilterSpecV2? filters,
  }) = _InterleavedListSectionParamsV2;

  factory InterleavedListSectionParamsV2.fromJson(Map<String, dynamic> json) =>
      _$InterleavedListSectionParamsV2FromJson(json);
}

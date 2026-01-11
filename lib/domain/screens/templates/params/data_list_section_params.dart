import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/enrichment_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/related_data_config.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';

part 'data_list_section_params.freezed.dart';
part 'data_list_section_params.g.dart';

/// Params for list-style templates (task/project/value lists).
@freezed
abstract class DataListSectionParams with _$DataListSectionParams {
  const factory DataListSectionParams({
    required DataConfig config,
    required TaskTileVariant taskTileVariant,
    required ProjectTileVariant projectTileVariant,
    required ValueTileVariant valueTileVariant,
    @Default(<RelatedDataConfig>[]) List<RelatedDataConfig> relatedData,
    DisplayConfig? display,
    EnrichmentConfig? enrichment,
  }) = _DataListSectionParams;

  factory DataListSectionParams.fromJson(Map<String, dynamic> json) =>
      _$DataListSectionParamsFromJson(json);
}

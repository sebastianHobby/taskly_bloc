import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/templates/data_list_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/screen_item_tile_variants.dart';

part 'interleaved_list_section_params.freezed.dart';
part 'interleaved_list_section_params.g.dart';

/// Params for the interleaved list template.
///
/// This template merges multiple list sources (tasks/projects/values) into a
/// single ordered list of `ScreenItem`s.
@freezed
abstract class InterleavedListSectionParams
    with _$InterleavedListSectionParams {
  const factory InterleavedListSectionParams({
    required List<InterleavedListSource> sources,
    required TaskTileVariant taskTileVariant,
    required ProjectTileVariant projectTileVariant,
    required ValueTileVariant valueTileVariant,
    @Default(InterleavedOrderStrategy.updatedAtDesc)
    InterleavedOrderStrategy orderStrategy,
  }) = _InterleavedListSectionParams;

  factory InterleavedListSectionParams.fromJson(Map<String, dynamic> json) =>
      _$InterleavedListSectionParamsFromJson(json);
}

@freezed
abstract class InterleavedListSource with _$InterleavedListSource {
  const factory InterleavedListSource({
    required DataListSectionParams params,
  }) = _InterleavedListSource;

  factory InterleavedListSource.fromJson(Map<String, dynamic> json) =>
      _$InterleavedListSourceFromJson(json);
}

/// Ordering strategy for interleaved lists.
///
/// Kept intentionally small; add more strategies only when a screen requires it.
enum InterleavedOrderStrategy {
  @JsonValue('updated_at_desc')
  updatedAtDesc,

  @JsonValue('created_at_desc')
  createdAtDesc,

  @JsonValue('deadline_date_asc')
  deadlineDateAsc,

  @JsonValue('start_date_asc')
  startDateAsc,
}

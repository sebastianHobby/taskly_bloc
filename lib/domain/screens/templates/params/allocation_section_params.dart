import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';

part 'allocation_section_params.freezed.dart';
part 'allocation_section_params.g.dart';

/// Params for the allocation template.
@freezed
abstract class AllocationSectionParams with _$AllocationSectionParams {
  const factory AllocationSectionParams({
    required TaskTileVariant taskTileVariant,
    @NullableTaskQueryConverter() TaskQuery? sourceFilter,
    int? maxTasks,
    @Default(AllocationDisplayMode.pinnedFirst)
    AllocationDisplayMode displayMode,
    @Default(true) bool showExcludedWarnings,
    @Default(false) bool showExcludedSection,
  }) = _AllocationSectionParams;

  factory AllocationSectionParams.fromJson(Map<String, dynamic> json) =>
      _$AllocationSectionParamsFromJson(json);
}

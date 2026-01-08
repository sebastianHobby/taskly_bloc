import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity_header_section_params.freezed.dart';
part 'entity_header_section_params.g.dart';

/// Params for the entity header template.
///
/// Used by entity detail screens (project/value) to render a summary header.
@freezed
abstract class EntityHeaderSectionParams with _$EntityHeaderSectionParams {
  const factory EntityHeaderSectionParams({
    required String entityType,
    required String entityId,
    @Default(true) bool showCheckbox,
    @Default(true) bool showMetadata,
  }) = _EntityHeaderSectionParams;

  factory EntityHeaderSectionParams.fromJson(Map<String, dynamic> json) =>
      _$EntityHeaderSectionParamsFromJson(json);
}

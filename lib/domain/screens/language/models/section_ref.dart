import 'package:freezed_annotation/freezed_annotation.dart';

part 'section_ref.freezed.dart';
part 'section_ref.g.dart';

/// Reference to a section template and its JSON parameters.
///
/// This is the persisted shape of screen configuration.
@freezed
abstract class SectionRef with _$SectionRef {
  const factory SectionRef({
    required String templateId,
    @Default(<String, dynamic>{}) Map<String, dynamic> params,
    SectionOverrides? overrides,
  }) = _SectionRef;

  factory SectionRef.fromJson(Map<String, dynamic> json) =>
      _$SectionRefFromJson(json);
}

/// Optional overrides that can be applied on top of a template.
@freezed
abstract class SectionOverrides with _$SectionOverrides {
  const factory SectionOverrides({
    String? title,
    @Default(true) bool enabled,
  }) = _SectionOverrides;

  factory SectionOverrides.fromJson(Map<String, dynamic> json) =>
      _$SectionOverridesFromJson(json);
}

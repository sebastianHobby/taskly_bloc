import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_chrome.dart';
import 'package:taskly_bloc/domain/models/screens/screen_gate_config.dart';
import 'package:taskly_bloc/domain/models/screens/section_ref.dart';
import 'package:taskly_bloc/domain/models/screens/screen_source.dart';

part 'screen_definition.freezed.dart';
part 'screen_definition.g.dart';

/// A screen definition describing a navigable screen in the app.
///
/// All screens flow through the same rendering pipeline:
/// ScreenDefinition -> sections (list of SectionRef) -> template interpreters.
@freezed
abstract class ScreenDefinition with _$ScreenDefinition {
  const factory ScreenDefinition({
    required String id,
    required String screenKey,
    required String name,

    /// Audit fields
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Sections that make up the screen.
    @Default(<SectionRef>[]) List<SectionRef> sections,

    /// Optional screen-level gate. When active, the screen renders only the
    /// gate's full-screen section instead of [sections].
    ScreenGateConfig? gate,

    /// Source of this screen definition (system template vs user-defined)
    @Default(ScreenSource.userDefined) ScreenSource screenSource,

    /// UI chrome configuration (icon, badges, app bar actions, FAB, etc.).
    @Default(ScreenChrome.empty) ScreenChrome chrome,
  }) = _ScreenDefinition;
  const ScreenDefinition._();

  factory ScreenDefinition.fromJson(Map<String, dynamic> json) =>
      _$ScreenDefinitionFromJson(json);

  /// Whether this is a system-provided screen (convenience getter).
  bool get isSystemScreen => screenSource == ScreenSource.systemTemplate;
}

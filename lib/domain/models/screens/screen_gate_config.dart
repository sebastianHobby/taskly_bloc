import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/section_ref.dart';

part 'screen_gate_config.freezed.dart';
part 'screen_gate_config.g.dart';

/// A screen-level gate that can replace a screen's sections with a single
/// full-screen template while some criteria is not satisfied.
@freezed
abstract class ScreenGateConfig with _$ScreenGateConfig {
  const factory ScreenGateConfig({
    required ScreenGateCriteria criteria,

    /// The full-screen section to render while the gate is active.
    required SectionRef section,
  }) = _ScreenGateConfig;

  factory ScreenGateConfig.fromJson(Map<String, dynamic> json) =>
      _$ScreenGateConfigFromJson(json);
}

/// Criteria for enabling a [ScreenGateConfig].
///
/// This is intentionally small to start; add additional criteria variants as
/// needed.
@Freezed(unionKey: 'type')
sealed class ScreenGateCriteria with _$ScreenGateCriteria {
  /// Gate is active when the user has not selected a focus mode yet.
  const factory ScreenGateCriteria.allocationFocusModeNotSelected() =
      AllocationFocusModeNotSelectedGateCriteria;

  factory ScreenGateCriteria.fromJson(Map<String, dynamic> json) =>
      _$ScreenGateCriteriaFromJson(json);
}

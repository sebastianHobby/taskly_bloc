import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_response_config.freezed.dart';
part 'tracker_response_config.g.dart';

@freezed
abstract class TrackerResponseConfig with _$TrackerResponseConfig {
  const factory TrackerResponseConfig.choice({
    required List<String> options,
  }) = ChoiceConfig;

  const factory TrackerResponseConfig.scale({
    @Default(1) int min,
    @Default(5) int max,
    String? minLabel,
    String? maxLabel,
  }) = ScaleConfig;

  const factory TrackerResponseConfig.yesNo() = YesNoConfig;

  factory TrackerResponseConfig.fromJson(Map<String, dynamic> json) =>
      _$TrackerResponseConfigFromJson(json);
}

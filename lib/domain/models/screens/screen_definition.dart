import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';

part 'screen_definition.freezed.dart';
part 'screen_definition.g.dart';

/// Flat class for screen definitions wrapping ViewDefinition
@freezed
abstract class ScreenDefinition with _$ScreenDefinition {
  const factory ScreenDefinition({
    required String id,
    required String screenKey,
    required String name,
    required ViewDefinition view,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? iconName,
    @Default(false) bool isSystem,
    @Default(true) bool isActive,
    @Default(0) int sortOrder,
    @Default(ScreenCategory.workspace) ScreenCategory category,
  }) = _ScreenDefinition;

  factory ScreenDefinition.fromJson(Map<String, dynamic> json) =>
      _$ScreenDefinitionFromJson(json);
}

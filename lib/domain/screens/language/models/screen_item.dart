import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';

part 'screen_item.freezed.dart';

/// A typed item that can be rendered inside list-based screen templates.
///
/// This replaces legacy `List<dynamic>` payloads so mixed entity lists can be
/// handled safely.
@freezed
sealed class ScreenItem with _$ScreenItem {
  const factory ScreenItem.task(Task task) = ScreenItemTask;
  const factory ScreenItem.project(Project project) = ScreenItemProject;
  const factory ScreenItem.value(Value value) = ScreenItemValue;

  /// Optional structural items.
  const factory ScreenItem.header(String title) = ScreenItemHeader;
  const factory ScreenItem.divider() = ScreenItemDivider;
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_domain/domain/core/model/project.dart';
import 'package:taskly_domain/domain/core/model/task.dart';
import 'package:taskly_domain/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_tile_capabilities.dart';

part 'screen_item.freezed.dart';

/// A typed item that can be rendered inside list-based screen templates.
///
/// This replaces legacy `List<dynamic>` payloads so mixed entity lists can be
/// handled safely.
@freezed
sealed class ScreenItem with _$ScreenItem {
  const factory ScreenItem.task(
    Task task, {

    /// Domain-sourced tile capability policy for this item.
    ///
    /// Migration policy: optional-first; will become required once all item
    /// producers are migrated.
    EntityTileCapabilities? tileCapabilities,
  }) = ScreenItemTask;

  const factory ScreenItem.project(
    Project project, {

    /// Domain-sourced tile capability policy for this item.
    ///
    /// Migration policy: optional-first; will become required once all item
    /// producers are migrated.
    EntityTileCapabilities? tileCapabilities,
  }) = ScreenItemProject;

  const factory ScreenItem.value(
    Value value, {

    /// Domain-sourced tile capability policy for this item.
    ///
    /// Migration policy: optional-first; will become required once all item
    /// producers are migrated.
    EntityTileCapabilities? tileCapabilities,
  }) = ScreenItemValue;

  /// Optional structural items.
  const factory ScreenItem.header(String title) = ScreenItemHeader;
  const factory ScreenItem.divider() = ScreenItemDivider;
}

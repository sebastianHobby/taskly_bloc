import 'package:flutter/foundation.dart';

/// High-level entity kind for catalogue renderers.
enum EntityKind { task, project }

/// Stable reference to an entity.
@immutable
final class EntityRef {
  const EntityRef.task(this.id) : kind = EntityKind.task;
  const EntityRef.project(this.id) : kind = EntityKind.project;

  final EntityKind kind;
  final String id;

  @override
  bool operator ==(Object other) {
    return other is EntityRef && other.kind == kind && other.id == id;
  }

  @override
  int get hashCode => Object.hash(kind, id);
}

/// Curated badge kinds used across catalogue renderers.
enum BadgeKind { due, starts, ongoing, pinned }

/// A small badge rendered near an entity title.
///
/// The app owns user-facing strings; taskly_ui only renders them.
@immutable
final class BadgeSpec {
  const BadgeSpec({required this.kind, required this.label});

  final BadgeKind kind;
  final String label;
}

/// Curated trailing affordances.
enum TrailingSpec {
  none,

  /// Renders a canonical overflow ("…") button.
  overflowButton,
}

/// Curated visual variants for entity tiles.
///
/// Start with a single variant; add more only when required.
enum TileVariant { standard }

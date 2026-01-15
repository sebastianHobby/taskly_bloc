import 'package:flutter/foundation.dart';

/// Stable key for persisting presentation-only UI state (e.g. PageStorage).
///
/// This intentionally keeps the current string format so existing persisted UI
/// state does not reset.
@immutable
final class SectionPersistenceKey {
  factory SectionPersistenceKey.fromParts({
    required String screenKey,
    required String sectionTemplateId,
    required int sectionIndex,
  }) {
    return SectionPersistenceKey._(
      '$screenKey:$sectionTemplateId:$sectionIndex',
    );
  }
  const SectionPersistenceKey._(this.value);

  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) {
    return other is SectionPersistenceKey && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

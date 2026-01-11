import 'dart:async';

/// Interprets a section template into reactive data for rendering.
abstract interface class SectionTemplateInterpreter<P> {
  String get templateId;

  Stream<Object?> watch(P params);

  Future<Object?> fetch(P params);
}

import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';

/// Interpreted data for an entire screen.
///
/// Emitted by the unified screen rendering pipeline.
@immutable
class ScreenData {
  const ScreenData({
    required this.definition,
    required this.sections,
    this.isLoading = false,
    this.error,
  });

  /// Create a loading state
  factory ScreenData.loading(ScreenDefinition definition) {
    return ScreenData(
      definition: definition,
      sections: const [],
      isLoading: true,
    );
  }

  /// Create an error state
  factory ScreenData.error(ScreenDefinition definition, String message) {
    return ScreenData(
      definition: definition,
      sections: const [],
      error: message,
    );
  }

  /// The screen definition being rendered
  final ScreenDefinition definition;

  /// Data for each section, indexed by section position
  final List<SectionVm> sections;

  /// Whether any section is currently loading
  final bool isLoading;

  /// Error message if screen failed to load
  final String? error;

  ScreenData copyWith({
    ScreenDefinition? definition,
    List<SectionVm>? sections,
    bool? isLoading,
    String? error,
  }) {
    return ScreenData(
      definition: definition ?? this.definition,
      sections: sections ?? this.sections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenData &&
        other.definition == definition &&
        listEquals(other.sections, sections) &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
    definition,
    Object.hashAll(sections),
    isLoading,
    error,
  );
}

import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_result.dart';

/// Interpreted data for an entire screen.
///
/// Emitted by [ScreenDataInterpreter.watchScreen] as a stream.
/// Only applicable to [DataDrivenScreenDefinition] screens.
@immutable
class ScreenData {
  const ScreenData({
    required this.definition,
    required this.sections,
    required this.supportBlocks,
    this.isLoading = false,
    this.error,
  });

  /// Create a loading state
  factory ScreenData.loading(DataDrivenScreenDefinition definition) {
    return ScreenData(
      definition: definition,
      sections: const [],
      supportBlocks: const [],
      isLoading: true,
    );
  }

  /// Create an error state
  factory ScreenData.error(
    DataDrivenScreenDefinition definition,
    String message,
  ) {
    return ScreenData(
      definition: definition,
      sections: const [],
      supportBlocks: const [],
      error: message,
    );
  }

  /// The screen definition being rendered
  final DataDrivenScreenDefinition definition;

  /// Data for each section, indexed by section position
  final List<SectionDataWithMeta> sections;

  /// Computed support block results
  final List<SupportBlockWithMeta> supportBlocks;

  /// Whether any section is currently loading
  final bool isLoading;

  /// Error message if screen failed to load
  final String? error;

  ScreenData copyWith({
    DataDrivenScreenDefinition? definition,
    List<SectionDataWithMeta>? sections,
    List<SupportBlockWithMeta>? supportBlocks,
    bool? isLoading,
    String? error,
  }) {
    return ScreenData(
      definition: definition ?? this.definition,
      sections: sections ?? this.sections,
      supportBlocks: supportBlocks ?? this.supportBlocks,
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
        listEquals(other.supportBlocks, supportBlocks) &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
    definition,
    Object.hashAll(sections),
    Object.hashAll(supportBlocks),
    isLoading,
    error,
  );
}

/// Section data with metadata for rendering.
@immutable
class SectionDataWithMeta {
  const SectionDataWithMeta({
    required this.index,
    required this.result,
    this.title,
    this.isLoading = false,
    this.error,
    this.displayConfig,
  });

  final int index;
  final String? title;
  final SectionDataResult result;
  final bool isLoading;
  final String? error;
  final DisplayConfig? displayConfig;

  SectionDataWithMeta copyWith({
    int? index,
    String? title,
    SectionDataResult? result,
    bool? isLoading,
    String? error,
    DisplayConfig? displayConfig,
  }) {
    return SectionDataWithMeta(
      index: index ?? this.index,
      title: title ?? this.title,
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      displayConfig: displayConfig ?? this.displayConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SectionDataWithMeta &&
        other.index == index &&
        other.title == title &&
        other.result == result &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.displayConfig == displayConfig;
  }

  @override
  int get hashCode =>
      Object.hash(index, title, result, isLoading, error, displayConfig);
}

/// Support block result with metadata.
@immutable
class SupportBlockWithMeta {
  const SupportBlockWithMeta({
    required this.index,
    required this.result,
  });

  final int index;
  final SupportBlockResult result;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupportBlockWithMeta &&
        other.index == index &&
        other.result == result;
  }

  @override
  int get hashCode => Object.hash(index, result);
}

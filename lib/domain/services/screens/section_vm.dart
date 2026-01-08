import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';

/// View model for a resolved screen section.
@immutable
class SectionVm {
  const SectionVm({
    required this.index,
    required this.templateId,
    required this.params,
    this.title,
    this.data,
    this.displayConfig,
    this.isLoading = false,
    this.error,
  });

  final int index;
  final String templateId;
  final Object params;
  final String? title;
  final Object? data;
  final DisplayConfig? displayConfig;
  final bool isLoading;
  final String? error;

  SectionVm copyWith({
    int? index,
    String? templateId,
    Object? params,
    String? title,
    Object? data,
    DisplayConfig? displayConfig,
    bool? isLoading,
    String? error,
  }) {
    return SectionVm(
      index: index ?? this.index,
      templateId: templateId ?? this.templateId,
      params: params ?? this.params,
      title: title ?? this.title,
      data: data ?? this.data,
      displayConfig: displayConfig ?? this.displayConfig,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SectionVm &&
        other.index == index &&
        other.templateId == templateId &&
      other.params == params &&
        other.title == title &&
        other.data == data &&
        other.displayConfig == displayConfig &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
    index,
    templateId,
    params,
    title,
    data,
    displayConfig,
    isLoading,
    error,
  );
}

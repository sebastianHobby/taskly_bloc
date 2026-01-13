import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';

/// Runtime data for a typed [ScreenSpec].
///
/// This is the system-screen-only rendering path for the hard cutover.
@immutable
class ScreenSpecData {
  const ScreenSpecData({
    required this.spec,
    required this.template,
    required this.sections,
    this.error,
  });

  final ScreenSpec spec;

  /// The effective template to render.
  ///
  /// This may differ from [ScreenSpec.template] when a gate is active.
  final ScreenTemplateSpec template;

  final SlottedSectionVms sections;

  final String? error;

  bool get hasError => error != null;
}

/// A group of resolved section view-models assigned to well-known layout slots.
@immutable
class SlottedSectionVms {
  const SlottedSectionVms({
    this.header = const <SectionVm>[],
    this.primary = const <SectionVm>[],
  });

  final List<SectionVm> header;
  final List<SectionVm> primary;

  bool get isEmpty => header.isEmpty && primary.isEmpty;

  List<SectionVm> forSlot(SlotId slotId) {
    return switch (slotId) {
      SlotId.header => header,
      SlotId.primary => primary,
    };
  }
}

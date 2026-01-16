import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/section_renderer_registry.dart';

/// Widget that renders a section from interpreted screen data.
///
/// Handles different section types (data, allocation, agenda) and
/// displays appropriate UI for each.
class SectionWidget extends StatelessWidget {
  /// Creates a SectionWidget.
  const SectionWidget({
    required this.section,
    super.key,
    this.persistenceKey,
    this.displayConfig,
    this.focusMode,
    this.onEntityTap,
    this.onEntityHeaderTap,
  });

  /// The section data to render
  final SectionVm section;

  /// Stable key for persisting presentation-only UI state (e.g. via PageStorage).
  ///
  /// This is derived in the unified screen rendering path and should be stable
  /// for a given screen + section instance.
  final String? persistenceKey;

  /// Optional display configuration override
  final DisplayConfig? displayConfig;

  /// Current focus mode (for allocation sections)
  final FocusMode? focusMode;

  /// Callback when an entity is tapped
  final void Function(dynamic entity)? onEntityTap;

  /// Callback when the entity header module is tapped.
  ///
  /// This is separate from [onEntityTap] so detail pages can open editors from
  /// the header while list items still navigate to their routes.
  final VoidCallback? onEntityHeaderTap;

  @override
  Widget build(BuildContext context) {
    final registry = context.read<SectionRendererRegistry>();
    return registry.buildSection(
      context: context,
      section: section,
      persistenceKey: persistenceKey,
      displayConfig: displayConfig,
      focusMode: focusMode,
      onEntityTap: onEntityTap,
      onEntityHeaderTap: onEntityHeaderTap,
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Typography tokens for Taskly.
///
/// This is a ThemeExtension so templates/renderers can opt into mock-accurate
/// typography without changing the global Material text theme.
@immutable
class TasklyTypography extends ThemeExtension<TasklyTypography> {
  const TasklyTypography({
    required this.screenTitleTight,
    required this.badgeTinyCaps,
    required this.sectionHeaderHeavy,
    required this.agendaSectionHeaderHeavy,
    required this.subHeaderCaps,
    required this.filterControl,
    required this.agendaChipDateNumber,
    required this.agendaChipDateNumberSelected,
  });

  factory TasklyTypography.from({
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    final onSurfaceMuted = colorScheme.onSurfaceVariant;

    return TasklyTypography(
      screenTitleTight: (textTheme.titleLarge ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      badgeTinyCaps: (textTheme.labelSmall ?? const TextStyle()).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: onSurfaceMuted,
      ),
      sectionHeaderHeavy: (textTheme.titleLarge ?? const TextStyle()).copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
      agendaSectionHeaderHeavy: (textTheme.headlineSmall ?? const TextStyle())
          .copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
      subHeaderCaps: (textTheme.labelSmall ?? const TextStyle()).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: onSurfaceMuted,
      ),
      filterControl: (textTheme.labelLarge ?? const TextStyle()).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      agendaChipDateNumber: (textTheme.titleLarge ?? const TextStyle())
          .copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
      agendaChipDateNumberSelected: (textTheme.titleLarge ?? const TextStyle())
          .copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
    );
  }

  /// Tight, bold screen title (e.g. Someday / October 2023).
  final TextStyle screenTitleTight;

  /// Tiny uppercase badge label (e.g. Multi-Value, High Priority Value).
  final TextStyle badgeTinyCaps;

  /// Heavy section header (e.g. NO VALUE ASSIGNED).
  final TextStyle sectionHeaderHeavy;

  /// Heavy, prominent agenda section header (e.g. Today).
  final TextStyle agendaSectionHeaderHeavy;

  /// Small uppercase subheader (e.g. Project: X, Inbox (Value)).
  final TextStyle subHeaderCaps;

  /// Filter/sort control labels.
  final TextStyle filterControl;

  /// Agenda date chip number style (unselected).
  final TextStyle agendaChipDateNumber;

  /// Agenda date chip number style (selected).
  final TextStyle agendaChipDateNumberSelected;

  @override
  TasklyTypography copyWith({
    TextStyle? screenTitleTight,
    TextStyle? badgeTinyCaps,
    TextStyle? sectionHeaderHeavy,
    TextStyle? agendaSectionHeaderHeavy,
    TextStyle? subHeaderCaps,
    TextStyle? filterControl,
    TextStyle? agendaChipDateNumber,
    TextStyle? agendaChipDateNumberSelected,
  }) {
    return TasklyTypography(
      screenTitleTight: screenTitleTight ?? this.screenTitleTight,
      badgeTinyCaps: badgeTinyCaps ?? this.badgeTinyCaps,
      sectionHeaderHeavy: sectionHeaderHeavy ?? this.sectionHeaderHeavy,
      agendaSectionHeaderHeavy:
          agendaSectionHeaderHeavy ?? this.agendaSectionHeaderHeavy,
      subHeaderCaps: subHeaderCaps ?? this.subHeaderCaps,
      filterControl: filterControl ?? this.filterControl,
      agendaChipDateNumber: agendaChipDateNumber ?? this.agendaChipDateNumber,
      agendaChipDateNumberSelected:
          agendaChipDateNumberSelected ?? this.agendaChipDateNumberSelected,
    );
  }

  @override
  TasklyTypography lerp(ThemeExtension<TasklyTypography>? other, double t) {
    if (other is! TasklyTypography) return this;

    return TasklyTypography(
      screenTitleTight: TextStyle.lerp(
        screenTitleTight,
        other.screenTitleTight,
        t,
      )!,
      badgeTinyCaps: TextStyle.lerp(badgeTinyCaps, other.badgeTinyCaps, t)!,
      sectionHeaderHeavy: TextStyle.lerp(
        sectionHeaderHeavy,
        other.sectionHeaderHeavy,
        t,
      )!,
      agendaSectionHeaderHeavy: TextStyle.lerp(
        agendaSectionHeaderHeavy,
        other.agendaSectionHeaderHeavy,
        t,
      )!,
      subHeaderCaps: TextStyle.lerp(subHeaderCaps, other.subHeaderCaps, t)!,
      filterControl: TextStyle.lerp(filterControl, other.filterControl, t)!,
      agendaChipDateNumber: TextStyle.lerp(
        agendaChipDateNumber,
        other.agendaChipDateNumber,
        t,
      )!,
      agendaChipDateNumberSelected: TextStyle.lerp(
        agendaChipDateNumberSelected,
        other.agendaChipDateNumberSelected,
        t,
      )!,
    );
  }
}

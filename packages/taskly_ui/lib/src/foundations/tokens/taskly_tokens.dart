import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class TasklyTokens extends ThemeExtension<TasklyTokens> {
  const TasklyTokens({
    required this.spaceXxs,
    required this.spaceXxs2,
    required this.spaceXs,
    required this.spaceXs2,
    required this.spaceSm,
    required this.spaceSm2,
    required this.spaceMd,
    required this.spaceMd2,
    required this.spaceLg,
    required this.spaceLg2,
    required this.spaceLg3,
    required this.spaceXl,
    required this.spaceXxl,
    required this.radiusXxs,
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusMd2,
    required this.radiusLg,
    required this.radiusLg2,
    required this.radiusXxl,
    required this.radiusPill,
    required this.taskRadius,
    required this.projectRadius,
    required this.taskPadding,
    required this.projectPadding,
    required this.sectionPaddingH,
    required this.progressRingSize,
    required this.progressRingSizeSmall,
    required this.progressRingStrokeSmall,
    required this.checkboxSize,
    required this.cardShadowBlur,
    required this.cardShadowOffset,
    required this.feedRowIndent,
    required this.feedEntityRowSpacing,
    required this.feedSectionSpacing,
    required this.minTapTargetSize,
    required this.iconButtonMinSize,
    required this.iconButtonPadding,
    required this.iconButtonBackgroundAlpha,
    required this.anytimeAppBarHeight,
    required this.scheduledAppBarHeight,
    required this.anytimeHeaderPadding,
    required this.valueItemWidth,
    required this.filterRowSpacing,
    required this.filterPillPadding,
    required this.filterPillRadius,
    required this.filterPillIconSize,
    required this.monthStripDotSize,
    required this.scheduledDaySectionSpacing,
    required this.urgentSurface,
    required this.warningSurface,
    required this.safeSurface,
    required this.neonAccent,
    required this.glassBorder,
  });

  factory TasklyTokens.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;

    const spaceXxs = 2.0;
    const spaceXxs2 = 3.0;
    const spaceXs = 4.0;
    const spaceXs2 = 6.0;
    const spaceSm = 8.0;
    const spaceSm2 = 10.0;
    const spaceMd = 12.0;
    const spaceMd2 = 14.0;
    const spaceLg = 16.0;
    const spaceLg2 = 18.0;
    const spaceLg3 = 20.0;
    const spaceXl = 24.0;
    const spaceXxl = 32.0;

    const radiusXxs = 2.0;
    const radiusXs = 4.0;
    const radiusSm = 8.0;
    const radiusMd = 12.0;
    const radiusMd2 = 14.0;
    const radiusLg = 16.0;
    const radiusLg2 = 18.0;
    const radiusXxl = 28.0;
    const radiusPill = 999.0;

    return TasklyTokens(
      spaceXxs: spaceXxs,
      spaceXxs2: spaceXxs2,
      spaceXs: spaceXs,
      spaceXs2: spaceXs2,
      spaceSm: spaceSm,
      spaceSm2: spaceSm2,
      spaceMd: spaceMd,
      spaceMd2: spaceMd2,
      spaceLg: spaceLg,
      spaceLg2: spaceLg2,
      spaceLg3: spaceLg3,
      spaceXl: spaceXl,
      spaceXxl: spaceXxl,
      radiusXxs: radiusXxs,
      radiusXs: radiusXs,
      radiusSm: radiusSm,
      radiusMd: radiusMd,
      radiusMd2: radiusMd2,
      radiusLg: radiusLg,
      radiusLg2: radiusLg2,
      radiusXxl: radiusXxl,
      radiusPill: radiusPill,
      taskRadius: radiusMd,
      projectRadius: radiusLg,
      taskPadding: EdgeInsets.all(spaceMd),
      projectPadding: EdgeInsets.all(spaceLg),
      sectionPaddingH: spaceLg,
      progressRingSize: 44,
      progressRingSizeSmall: 28,
      progressRingStrokeSmall: spaceXxs,
      checkboxSize: spaceLg3,
      cardShadowBlur: spaceSm,
      cardShadowOffset: const Offset(0, 2),
      feedRowIndent: spaceSm2,
      feedEntityRowSpacing: spaceSm2,
      feedSectionSpacing: spaceXl,
      minTapTargetSize: 40,
      iconButtonMinSize: 44,
      iconButtonPadding: EdgeInsets.all(spaceSm2),
      iconButtonBackgroundAlpha: 0.08,
      anytimeAppBarHeight: 60,
      scheduledAppBarHeight: 60,
      anytimeHeaderPadding: EdgeInsets.fromLTRB(
        spaceLg,
        spaceSm2,
        spaceLg,
        spaceSm,
      ),
      valueItemWidth: 72,
      filterRowSpacing: spaceSm,
      filterPillPadding: EdgeInsets.symmetric(
        horizontal: spaceSm2,
        vertical: spaceXs2,
      ),
      filterPillRadius: radiusSm,
      filterPillIconSize: spaceMd2,
      monthStripDotSize: 5,
      scheduledDaySectionSpacing: spaceLg,
      urgentSurface: scheme.errorContainer.withValues(alpha: 0.2),
      warningSurface: scheme.secondaryContainer.withValues(alpha: 0.2),
      safeSurface: scheme.tertiaryContainer.withValues(alpha: 0.15),
      neonAccent: scheme.primary,
      glassBorder: scheme.onSurface.withValues(alpha: 0.1),
    );
  }

  factory TasklyTokens.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyTokens>() ?? TasklyTokens.fromTheme(theme);
  }

  final double spaceXxs;
  final double spaceXxs2;
  final double spaceXs;
  final double spaceXs2;
  final double spaceSm;
  final double spaceSm2;
  final double spaceMd;
  final double spaceMd2;
  final double spaceLg;
  final double spaceLg2;
  final double spaceLg3;
  final double spaceXl;
  final double spaceXxl;

  final double radiusXxs;
  final double radiusXs;
  final double radiusSm;
  final double radiusMd;
  final double radiusMd2;
  final double radiusLg;
  final double radiusLg2;
  final double radiusXxl;
  final double radiusPill;

  final double taskRadius;
  final double projectRadius;
  final EdgeInsets taskPadding;
  final EdgeInsets projectPadding;
  final double sectionPaddingH;
  final double progressRingSize;
  final double progressRingSizeSmall;
  final double progressRingStrokeSmall;
  final double checkboxSize;
  final double cardShadowBlur;
  final Offset cardShadowOffset;

  final double feedRowIndent;
  final double feedEntityRowSpacing;
  final double feedSectionSpacing;

  final double minTapTargetSize;
  final double iconButtonMinSize;
  final EdgeInsets iconButtonPadding;
  final double iconButtonBackgroundAlpha;

  final double anytimeAppBarHeight;
  final double scheduledAppBarHeight;
  final EdgeInsets anytimeHeaderPadding;
  final double valueItemWidth;
  final double filterRowSpacing;
  final EdgeInsets filterPillPadding;
  final double filterPillRadius;
  final double filterPillIconSize;
  final double monthStripDotSize;
  final double scheduledDaySectionSpacing;

  final Color urgentSurface;
  final Color warningSurface;
  final Color safeSurface;
  final Color neonAccent;
  final Color glassBorder;

  @override
  TasklyTokens copyWith({
    double? spaceXxs,
    double? spaceXxs2,
    double? spaceXs,
    double? spaceXs2,
    double? spaceSm,
    double? spaceSm2,
    double? spaceMd,
    double? spaceMd2,
    double? spaceLg,
    double? spaceLg2,
    double? spaceLg3,
    double? spaceXl,
    double? spaceXxl,
    double? radiusXxs,
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusMd2,
    double? radiusLg,
    double? radiusLg2,
    double? radiusXxl,
    double? radiusPill,
    double? taskRadius,
    double? projectRadius,
    EdgeInsets? taskPadding,
    EdgeInsets? projectPadding,
    double? sectionPaddingH,
    double? progressRingSize,
    double? progressRingSizeSmall,
    double? progressRingStrokeSmall,
    double? checkboxSize,
    double? cardShadowBlur,
    Offset? cardShadowOffset,
    double? feedRowIndent,
    double? feedEntityRowSpacing,
    double? feedSectionSpacing,
    double? minTapTargetSize,
    double? iconButtonMinSize,
    EdgeInsets? iconButtonPadding,
    double? iconButtonBackgroundAlpha,
    double? anytimeAppBarHeight,
    double? scheduledAppBarHeight,
    EdgeInsets? anytimeHeaderPadding,
    double? valueItemWidth,
    double? filterRowSpacing,
    EdgeInsets? filterPillPadding,
    double? filterPillRadius,
    double? filterPillIconSize,
    double? monthStripDotSize,
    double? scheduledDaySectionSpacing,
    Color? urgentSurface,
    Color? warningSurface,
    Color? safeSurface,
    Color? neonAccent,
    Color? glassBorder,
  }) {
    return TasklyTokens(
      spaceXxs: spaceXxs ?? this.spaceXxs,
      spaceXxs2: spaceXxs2 ?? this.spaceXxs2,
      spaceXs: spaceXs ?? this.spaceXs,
      spaceXs2: spaceXs2 ?? this.spaceXs2,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceSm2: spaceSm2 ?? this.spaceSm2,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceMd2: spaceMd2 ?? this.spaceMd2,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceLg2: spaceLg2 ?? this.spaceLg2,
      spaceLg3: spaceLg3 ?? this.spaceLg3,
      spaceXl: spaceXl ?? this.spaceXl,
      spaceXxl: spaceXxl ?? this.spaceXxl,
      radiusXxs: radiusXxs ?? this.radiusXxs,
      radiusXs: radiusXs ?? this.radiusXs,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusMd2: radiusMd2 ?? this.radiusMd2,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusLg2: radiusLg2 ?? this.radiusLg2,
      radiusXxl: radiusXxl ?? this.radiusXxl,
      radiusPill: radiusPill ?? this.radiusPill,
      taskRadius: taskRadius ?? this.taskRadius,
      projectRadius: projectRadius ?? this.projectRadius,
      taskPadding: taskPadding ?? this.taskPadding,
      projectPadding: projectPadding ?? this.projectPadding,
      sectionPaddingH: sectionPaddingH ?? this.sectionPaddingH,
      progressRingSize: progressRingSize ?? this.progressRingSize,
      progressRingSizeSmall:
          progressRingSizeSmall ?? this.progressRingSizeSmall,
      progressRingStrokeSmall:
          progressRingStrokeSmall ?? this.progressRingStrokeSmall,
      checkboxSize: checkboxSize ?? this.checkboxSize,
      cardShadowBlur: cardShadowBlur ?? this.cardShadowBlur,
      cardShadowOffset: cardShadowOffset ?? this.cardShadowOffset,
      feedRowIndent: feedRowIndent ?? this.feedRowIndent,
      feedEntityRowSpacing: feedEntityRowSpacing ?? this.feedEntityRowSpacing,
      feedSectionSpacing: feedSectionSpacing ?? this.feedSectionSpacing,
      minTapTargetSize: minTapTargetSize ?? this.minTapTargetSize,
      iconButtonMinSize: iconButtonMinSize ?? this.iconButtonMinSize,
      iconButtonPadding: iconButtonPadding ?? this.iconButtonPadding,
      iconButtonBackgroundAlpha:
          iconButtonBackgroundAlpha ?? this.iconButtonBackgroundAlpha,
      anytimeAppBarHeight: anytimeAppBarHeight ?? this.anytimeAppBarHeight,
      scheduledAppBarHeight:
          scheduledAppBarHeight ?? this.scheduledAppBarHeight,
      anytimeHeaderPadding: anytimeHeaderPadding ?? this.anytimeHeaderPadding,
      valueItemWidth: valueItemWidth ?? this.valueItemWidth,
      filterRowSpacing: filterRowSpacing ?? this.filterRowSpacing,
      filterPillPadding: filterPillPadding ?? this.filterPillPadding,
      filterPillRadius: filterPillRadius ?? this.filterPillRadius,
      filterPillIconSize: filterPillIconSize ?? this.filterPillIconSize,
      monthStripDotSize: monthStripDotSize ?? this.monthStripDotSize,
      scheduledDaySectionSpacing:
          scheduledDaySectionSpacing ?? this.scheduledDaySectionSpacing,
      urgentSurface: urgentSurface ?? this.urgentSurface,
      warningSurface: warningSurface ?? this.warningSurface,
      safeSurface: safeSurface ?? this.safeSurface,
      neonAccent: neonAccent ?? this.neonAccent,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  TasklyTokens lerp(ThemeExtension<TasklyTokens>? other, double t) {
    if (other is! TasklyTokens) return this;

    return TasklyTokens(
      spaceXxs: lerpDouble(spaceXxs, other.spaceXxs, t) ?? spaceXxs,
      spaceXxs2: lerpDouble(spaceXxs2, other.spaceXxs2, t) ?? spaceXxs2,
      spaceXs: lerpDouble(spaceXs, other.spaceXs, t) ?? spaceXs,
      spaceXs2: lerpDouble(spaceXs2, other.spaceXs2, t) ?? spaceXs2,
      spaceSm: lerpDouble(spaceSm, other.spaceSm, t) ?? spaceSm,
      spaceSm2: lerpDouble(spaceSm2, other.spaceSm2, t) ?? spaceSm2,
      spaceMd: lerpDouble(spaceMd, other.spaceMd, t) ?? spaceMd,
      spaceMd2: lerpDouble(spaceMd2, other.spaceMd2, t) ?? spaceMd2,
      spaceLg: lerpDouble(spaceLg, other.spaceLg, t) ?? spaceLg,
      spaceLg2: lerpDouble(spaceLg2, other.spaceLg2, t) ?? spaceLg2,
      spaceLg3: lerpDouble(spaceLg3, other.spaceLg3, t) ?? spaceLg3,
      spaceXl: lerpDouble(spaceXl, other.spaceXl, t) ?? spaceXl,
      spaceXxl: lerpDouble(spaceXxl, other.spaceXxl, t) ?? spaceXxl,
      radiusXxs: lerpDouble(radiusXxs, other.radiusXxs, t) ?? radiusXxs,
      radiusXs: lerpDouble(radiusXs, other.radiusXs, t) ?? radiusXs,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t) ?? radiusSm,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t) ?? radiusMd,
      radiusMd2: lerpDouble(radiusMd2, other.radiusMd2, t) ?? radiusMd2,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t) ?? radiusLg,
      radiusLg2: lerpDouble(radiusLg2, other.radiusLg2, t) ?? radiusLg2,
      radiusXxl: lerpDouble(radiusXxl, other.radiusXxl, t) ?? radiusXxl,
      radiusPill: lerpDouble(radiusPill, other.radiusPill, t) ?? radiusPill,
      taskRadius: lerpDouble(taskRadius, other.taskRadius, t) ?? taskRadius,
      projectRadius:
          lerpDouble(projectRadius, other.projectRadius, t) ?? projectRadius,
      taskPadding:
          EdgeInsets.lerp(taskPadding, other.taskPadding, t) ?? taskPadding,
      projectPadding:
          EdgeInsets.lerp(projectPadding, other.projectPadding, t) ??
          projectPadding,
      sectionPaddingH:
          lerpDouble(sectionPaddingH, other.sectionPaddingH, t) ??
          sectionPaddingH,
      progressRingSize:
          lerpDouble(progressRingSize, other.progressRingSize, t) ??
          progressRingSize,
      progressRingSizeSmall:
          lerpDouble(progressRingSizeSmall, other.progressRingSizeSmall, t) ??
          progressRingSizeSmall,
      progressRingStrokeSmall:
          lerpDouble(
            progressRingStrokeSmall,
            other.progressRingStrokeSmall,
            t,
          ) ??
          progressRingStrokeSmall,
      checkboxSize:
          lerpDouble(checkboxSize, other.checkboxSize, t) ?? checkboxSize,
      cardShadowBlur:
          lerpDouble(cardShadowBlur, other.cardShadowBlur, t) ?? cardShadowBlur,
      cardShadowOffset:
          Offset.lerp(cardShadowOffset, other.cardShadowOffset, t) ??
          cardShadowOffset,
      feedRowIndent:
          lerpDouble(feedRowIndent, other.feedRowIndent, t) ?? feedRowIndent,
      feedEntityRowSpacing:
          lerpDouble(feedEntityRowSpacing, other.feedEntityRowSpacing, t) ??
          feedEntityRowSpacing,
      feedSectionSpacing:
          lerpDouble(feedSectionSpacing, other.feedSectionSpacing, t) ??
          feedSectionSpacing,
      minTapTargetSize:
          lerpDouble(minTapTargetSize, other.minTapTargetSize, t) ??
          minTapTargetSize,
      iconButtonMinSize:
          lerpDouble(iconButtonMinSize, other.iconButtonMinSize, t) ??
          iconButtonMinSize,
      iconButtonPadding:
          EdgeInsets.lerp(iconButtonPadding, other.iconButtonPadding, t) ??
          iconButtonPadding,
      iconButtonBackgroundAlpha:
          lerpDouble(
            iconButtonBackgroundAlpha,
            other.iconButtonBackgroundAlpha,
            t,
          ) ??
          iconButtonBackgroundAlpha,
      anytimeAppBarHeight:
          lerpDouble(anytimeAppBarHeight, other.anytimeAppBarHeight, t) ??
          anytimeAppBarHeight,
      scheduledAppBarHeight:
          lerpDouble(scheduledAppBarHeight, other.scheduledAppBarHeight, t) ??
          scheduledAppBarHeight,
      anytimeHeaderPadding:
          EdgeInsets.lerp(
            anytimeHeaderPadding,
            other.anytimeHeaderPadding,
            t,
          ) ??
          anytimeHeaderPadding,
      valueItemWidth:
          lerpDouble(valueItemWidth, other.valueItemWidth, t) ?? valueItemWidth,
      filterRowSpacing:
          lerpDouble(filterRowSpacing, other.filterRowSpacing, t) ??
          filterRowSpacing,
      filterPillPadding:
          EdgeInsets.lerp(filterPillPadding, other.filterPillPadding, t) ??
          filterPillPadding,
      filterPillRadius:
          lerpDouble(filterPillRadius, other.filterPillRadius, t) ??
          filterPillRadius,
      filterPillIconSize:
          lerpDouble(filterPillIconSize, other.filterPillIconSize, t) ??
          filterPillIconSize,
      monthStripDotSize:
          lerpDouble(monthStripDotSize, other.monthStripDotSize, t) ??
          monthStripDotSize,
      scheduledDaySectionSpacing:
          lerpDouble(
            scheduledDaySectionSpacing,
            other.scheduledDaySectionSpacing,
            t,
          ) ??
          scheduledDaySectionSpacing,
      urgentSurface: Color.lerp(urgentSurface, other.urgentSurface, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      safeSurface: Color.lerp(safeSurface, other.safeSurface, t)!,
      neonAccent: Color.lerp(neonAccent, other.neonAccent, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

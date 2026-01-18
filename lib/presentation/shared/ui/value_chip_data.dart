import 'package:flutter/material.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_ui/taskly_ui.dart';

/// Maps a domain [Value] into UI-only [ValueChipData].
extension ValueChipDataMapper on Value {
  ValueChipData toChipData(BuildContext context) {
    final valueColor = ColorUtils.fromHexWithThemeFallback(context, color);
    final iconData = getIconDataFromName(iconName) ?? Icons.star;

    return ValueChipData(
      label: name,
      color: valueColor,
      icon: iconData,
      semanticLabel: name,
    );
  }
}

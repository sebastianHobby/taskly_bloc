import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

/// Maps a domain [Value] into UI-only [TasklyValueRowData].
extension ValueTileModelMapper on Value {
  TasklyValueRowData toRowData(BuildContext context) {
    final accentColor = ColorUtils.valueColorForTheme(context, color);
    final iconData = getIconDataFromName(iconName) ?? Icons.star;

    return TasklyValueRowData(
      id: id,
      title: name,
      icon: iconData,
      accentColor: accentColor,
    );
  }
}

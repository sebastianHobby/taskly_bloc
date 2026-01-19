import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_entities.dart';

/// Maps a domain [Value] into UI-only [ValueTileModel] for catalogue renderers.
extension ValueTileModelMapper on Value {
  ValueTileModel toTileModel(BuildContext context) {
    final accentColor = ColorUtils.fromHexWithThemeFallback(context, color);
    final iconData = getIconDataFromName(iconName) ?? Icons.star;

    return ValueTileModel(
      id: id,
      title: name,
      icon: iconData,
      accentColor: accentColor,
    );
  }
}

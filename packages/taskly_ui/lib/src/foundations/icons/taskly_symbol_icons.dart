import 'package:flutter/widgets.dart';
import 'package:taskly_ui/src/foundations/icons/taskly_symbol_icon.dart';
import 'package:taskly_ui/src/foundations/icons/taskly_symbol_icons_generated.dart'
    as generated;

List<TasklySymbolIcon> get tasklySymbolIcons => generated.tasklySymbolIcons;

IconData? tasklySymbolIconDataFromName(String? name) {
  if (name == null) return null;
  return generated.tasklySymbolIconByName[name];
}

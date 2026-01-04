import 'package:flutter/material.dart';

/// Prototype settings for My Day screen UI experiments
class MyDayPrototypeSettings extends ChangeNotifier {
  MyDayPrototypeSettings._();

  static final MyDayPrototypeSettings instance = MyDayPrototypeSettings._();

  // Part 2: Header style options
  ValueHeaderStyle _headerStyle = ValueHeaderStyle.ribbon;
  ValueHeaderStyle get headerStyle => _headerStyle;
  set headerStyle(ValueHeaderStyle value) {
    _headerStyle = value;
    notifyListeners();
  }

  // Part 3 & 4: Value display on tasks
  bool _showValueIconsOnly = true;
  bool get showValueIconsOnly => _showValueIconsOnly;
  set showValueIconsOnly(bool value) {
    _showValueIconsOnly = value;
    notifyListeners();
  }

  // Part 4: Show "Why these tasks?" button
  bool _showWhyButton = false;
  bool get showWhyButton => _showWhyButton;
  set showWhyButton(bool value) {
    _showWhyButton = value;
    notifyListeners();
  }

  void reset() {
    _headerStyle = ValueHeaderStyle.ribbon;
    _showValueIconsOnly = true;
    _showWhyButton = false;
    notifyListeners();
  }
}

/// Header style options for value groups
enum ValueHeaderStyle {
  /// Tab-style with value name as box edge
  tabStyle,

  /// Ribbon with colored left bar (recommended)
  ribbon,

  /// Inset badge with underline
  insetBadge,
}

extension ValueHeaderStyleX on ValueHeaderStyle {
  String get displayName {
    switch (this) {
      case ValueHeaderStyle.tabStyle:
        return 'Tab Style';
      case ValueHeaderStyle.ribbon:
        return 'Ribbon';
      case ValueHeaderStyle.insetBadge:
        return 'Inset Badge';
    }
  }

  String get description {
    switch (this) {
      case ValueHeaderStyle.tabStyle:
        return 'Value name is the box edge';
      case ValueHeaderStyle.ribbon:
        return 'Modern with colored bar';
      case ValueHeaderStyle.insetBadge:
        return 'Clean with underline';
    }
  }
}

@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';

import 'helpers/test_helpers.dart';

void main() {
  testSafe('ValueChipData stores render data', () async {
    const data = ValueChipData(
      label: 'Focus',
      color: Colors.blue,
      icon: Icons.bolt,
      semanticLabel: 'Focus value',
    );

    expect(data.label, 'Focus');
    expect(data.color, Colors.blue);
    expect(data.icon, Icons.bolt);
    expect(data.semanticLabel, 'Focus value');
  });
}

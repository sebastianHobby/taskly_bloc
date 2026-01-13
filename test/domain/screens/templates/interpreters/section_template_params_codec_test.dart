import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'SectionTemplateParamsCodec is retired (typed ScreenSpec cutover)',
    () {},
    skip:
        'The JSON params codec was removed. System screens use ScreenSpec '
        '+ ScreenModuleSpec typed params directly.',
  );
}

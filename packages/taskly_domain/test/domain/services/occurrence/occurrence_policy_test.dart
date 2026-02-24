@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/services.dart';

void main() {
  testSafe('single-next surfaces always return true', () async {
    expect(
      OccurrencePolicy.showsSingleNextOnly(
        surface: RecurrenceDisplaySurface.planMyDay,
        repeatFromCompletion: false,
      ),
      isTrue,
    );
    expect(
      OccurrencePolicy.showsSingleNextOnly(
        surface: RecurrenceDisplaySurface.planMyDay,
        repeatFromCompletion: true,
      ),
      isTrue,
    );
    expect(
      OccurrencePolicy.showsSingleNextOnly(
        surface: RecurrenceDisplaySurface.myDay,
        repeatFromCompletion: false,
      ),
      isTrue,
    );
    expect(
      OccurrencePolicy.showsSingleNextOnly(
        surface: RecurrenceDisplaySurface.projects,
        repeatFromCompletion: false,
      ),
      isTrue,
    );
    expect(
      OccurrencePolicy.showsSingleNextOnly(
        surface: RecurrenceDisplaySurface.notifications,
        repeatFromCompletion: false,
      ),
      isTrue,
    );
  });

  testSafe('scheduled remains hybrid by repeat mode', () async {
    expect(
      OccurrencePolicy.showsSingleNextOnly(
        surface: RecurrenceDisplaySurface.scheduled,
        repeatFromCompletion: true,
      ),
      isTrue,
    );
    expect(
      OccurrencePolicy.showsSingleNextOnly(
        surface: RecurrenceDisplaySurface.scheduled,
        repeatFromCompletion: false,
      ),
      isFalse,
    );
  });
}

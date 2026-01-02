import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/utils/responsive.dart';

void main() {
  group('Breakpoints', () {
    test('has correct constant values', () {
      expect(Breakpoints.compact, 600);
      expect(Breakpoints.medium, 840);
      expect(Breakpoints.expanded, 1200);
    });

    group('isCompact', () {
      test('returns true for width less than 600', () {
        expect(Breakpoints.isCompact(0), true);
        expect(Breakpoints.isCompact(599), true);
        expect(Breakpoints.isCompact(400), true);
      });

      test('returns false for width 600 or greater', () {
        expect(Breakpoints.isCompact(600), false);
        expect(Breakpoints.isCompact(840), false);
        expect(Breakpoints.isCompact(1200), false);
      });
    });

    group('isMedium', () {
      test('returns true for width between 600 and 839', () {
        expect(Breakpoints.isMedium(600), true);
        expect(Breakpoints.isMedium(700), true);
        expect(Breakpoints.isMedium(839), true);
      });

      test('returns false for width less than 600', () {
        expect(Breakpoints.isMedium(599), false);
        expect(Breakpoints.isMedium(400), false);
      });

      test('returns false for width 840 or greater', () {
        expect(Breakpoints.isMedium(840), false);
        expect(Breakpoints.isMedium(1000), false);
      });
    });

    group('isExpanded', () {
      test('returns true for width 840 or greater', () {
        expect(Breakpoints.isExpanded(840), true);
        expect(Breakpoints.isExpanded(1000), true);
        expect(Breakpoints.isExpanded(1200), true);
      });

      test('returns false for width less than 840', () {
        expect(Breakpoints.isExpanded(839), false);
        expect(Breakpoints.isExpanded(600), false);
        expect(Breakpoints.isExpanded(400), false);
      });
    });

    group('isLargeExpanded', () {
      test('returns true for width 1200 or greater', () {
        expect(Breakpoints.isLargeExpanded(1200), true);
        expect(Breakpoints.isLargeExpanded(1500), true);
        expect(Breakpoints.isLargeExpanded(2000), true);
      });

      test('returns false for width less than 1200', () {
        expect(Breakpoints.isLargeExpanded(1199), false);
        expect(Breakpoints.isLargeExpanded(840), false);
        expect(Breakpoints.isLargeExpanded(600), false);
      });
    });
  });

  group('WindowSizeClass', () {
    test('has three values', () {
      expect(WindowSizeClass.values.length, 3);
    });

    group('fromWidth', () {
      test('returns compact for width less than 600', () {
        expect(WindowSizeClass.fromWidth(0), WindowSizeClass.compact);
        expect(WindowSizeClass.fromWidth(400), WindowSizeClass.compact);
        expect(WindowSizeClass.fromWidth(599), WindowSizeClass.compact);
      });

      test('returns medium for width between 600 and 839', () {
        expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
        expect(WindowSizeClass.fromWidth(700), WindowSizeClass.medium);
        expect(WindowSizeClass.fromWidth(839), WindowSizeClass.medium);
      });

      test('returns expanded for width 840 or greater', () {
        expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
        expect(WindowSizeClass.fromWidth(1000), WindowSizeClass.expanded);
        expect(WindowSizeClass.fromWidth(1500), WindowSizeClass.expanded);
      });
    });

    group('isCompact', () {
      test('returns true only for compact', () {
        expect(WindowSizeClass.compact.isCompact, true);
        expect(WindowSizeClass.medium.isCompact, false);
        expect(WindowSizeClass.expanded.isCompact, false);
      });
    });

    group('isMedium', () {
      test('returns true only for medium', () {
        expect(WindowSizeClass.compact.isMedium, false);
        expect(WindowSizeClass.medium.isMedium, true);
        expect(WindowSizeClass.expanded.isMedium, false);
      });
    });

    group('isExpanded', () {
      test('returns true only for expanded', () {
        expect(WindowSizeClass.compact.isExpanded, false);
        expect(WindowSizeClass.medium.isExpanded, false);
        expect(WindowSizeClass.expanded.isExpanded, true);
      });
    });

    group('isAtLeastMedium', () {
      test('returns false for compact', () {
        expect(WindowSizeClass.compact.isAtLeastMedium, false);
      });

      test('returns true for medium and expanded', () {
        expect(WindowSizeClass.medium.isAtLeastMedium, true);
        expect(WindowSizeClass.expanded.isAtLeastMedium, true);
      });
    });
  });
}

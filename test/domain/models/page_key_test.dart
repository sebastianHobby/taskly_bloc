import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/page_key.dart';

void main() {
  group('PageKey', () {
    test('has all expected values', () {
      expect(PageKey.values, hasLength(7));
      expect(PageKey.values, contains(PageKey.tasksInbox));
      expect(PageKey.values, contains(PageKey.tasksToday));
      expect(PageKey.values, contains(PageKey.tasksUpcoming));
      expect(PageKey.values, contains(PageKey.taskOverview));
      expect(PageKey.values, contains(PageKey.projectOverview));
      expect(PageKey.values, contains(PageKey.labelOverview));
      expect(PageKey.values, contains(PageKey.labelValueOverview));
    });

    test('each PageKey has unique string key', () {
      expect(PageKey.tasksInbox.key, 'tasks_inbox');
      expect(PageKey.tasksToday.key, 'tasks_today');
      expect(PageKey.tasksUpcoming.key, 'tasks_upcoming');
      expect(PageKey.taskOverview.key, 'task_overview');
      expect(PageKey.projectOverview.key, 'project_overview');
      expect(PageKey.labelOverview.key, 'label_overview');
      expect(PageKey.labelValueOverview.key, 'label_value_overview');
    });

    group('fromKey', () {
      test('returns correct PageKey for valid key', () {
        expect(PageKey.fromKey('tasks_inbox'), PageKey.tasksInbox);
        expect(PageKey.fromKey('tasks_today'), PageKey.tasksToday);
        expect(PageKey.fromKey('tasks_upcoming'), PageKey.tasksUpcoming);
        expect(PageKey.fromKey('task_overview'), PageKey.taskOverview);
        expect(PageKey.fromKey('project_overview'), PageKey.projectOverview);
        expect(PageKey.fromKey('label_overview'), PageKey.labelOverview);
        expect(
          PageKey.fromKey('label_value_overview'),
          PageKey.labelValueOverview,
        );
      });

      test('throws ArgumentError for invalid key', () {
        expect(
          () => PageKey.fromKey('invalid_key'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('error message contains the invalid key', () {
        try {
          PageKey.fromKey('unknown_page');
          fail('Expected ArgumentError to be thrown');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect(e.toString(), contains('unknown_page'));
          expect(e.toString(), contains('Unknown page key'));
        }
      });

      test('is case sensitive', () {
        expect(
          () => PageKey.fromKey('TASKS_INBOX'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    test('all keys are unique', () {
      final keys = PageKey.values.map((e) => e.key).toSet();
      expect(keys.length, PageKey.values.length);
    });

    test('PageKey instances can be used in switch statements', () {
      String getPageName(PageKey key) {
        switch (key) {
          case PageKey.tasksInbox:
            return 'Inbox';
          case PageKey.tasksToday:
            return 'Today';
          case PageKey.tasksUpcoming:
            return 'Upcoming';
          case PageKey.taskOverview:
            return 'Tasks';
          case PageKey.projectOverview:
            return 'Projects';
          case PageKey.labelOverview:
            return 'Labels';
          case PageKey.labelValueOverview:
            return 'Label Values';
        }
      }

      expect(getPageName(PageKey.tasksInbox), 'Inbox');
      expect(getPageName(PageKey.tasksToday), 'Today');
      expect(getPageName(PageKey.projectOverview), 'Projects');
    });

    test('PageKey enum values are const', () {
      const key1 = PageKey.tasksInbox;
      const key2 = PageKey.tasksInbox;
      expect(identical(key1, key2), isTrue);
    });

    test('roundtrip conversion works correctly', () {
      for (final pageKey in PageKey.values) {
        final key = pageKey.key;
        final recovered = PageKey.fromKey(key);
        expect(recovered, equals(pageKey));
      }
    });
  });
}

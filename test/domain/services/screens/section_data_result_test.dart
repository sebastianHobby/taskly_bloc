import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_result.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';

import '../../../fixtures/test_data.dart';

void main() {
  group('SectionDataResult', () {
    group('DataSectionResult', () {
      test('creates with required fields', () {
        final result = SectionDataResult.data(
          items: [ScreenItem.task(TestData.task())],
        );

        expect(result, isA<DataSectionResult>());
        final dataResult = result as DataSectionResult;
        expect(dataResult.items, hasLength(1));
      });

      group('allTasks', () {
        test('returns tasks when primaryEntityType is task', () {
          final tasks = [TestData.task(), TestData.task()];
          final result = SectionDataResult.data(
            items: tasks.map(ScreenItem.task).toList(),
          );

          expect(result.allTasks, hasLength(2));
        });

        test('returns empty list when primaryEntityType is not task', () {
          final result = SectionDataResult.data(
            items: [ScreenItem.project(TestData.project())],
          );

          expect(result.allTasks, isEmpty);
        });
      });

      group('allProjects', () {
        test('returns projects when primaryEntityType is project', () {
          final projects = [TestData.project(), TestData.project()];
          final result = SectionDataResult.data(
            items: projects.map(ScreenItem.project).toList(),
          );

          expect(result.allProjects, hasLength(2));
        });

        test('returns empty list when primaryEntityType is not project', () {
          final result = SectionDataResult.data(
            items: [ScreenItem.task(TestData.task())],
          );

          expect(result.allProjects, isEmpty);
        });
      });

      group('allValues', () {
        test('returns labels when primaryEntityType is label', () {
          final values = [TestData.value(), TestData.value()];
          final result = SectionDataResult.data(
            items: values.map(ScreenItem.value).toList(),
          );

          expect(result.allValues, hasLength(2));
        });

        test('returns labels when primaryEntityType is value', () {
          final values = [
            TestData.value(priority: ValuePriority.medium),
          ];
          final result = SectionDataResult.data(
            items: values.map(ScreenItem.value).toList(),
          );

          expect(result.allValues, hasLength(1));
        });

        test(
          'returns empty list when primaryEntityType is not label/value',
          () {
            final result = SectionDataResult.data(
              items: [ScreenItem.task(TestData.task())],
            );

            expect(result.allValues, isEmpty);
          },
        );
      });
    });

    group('AllocationSectionResult', () {
      test('creates with required fields', () {
        final tasks = [TestData.task()];
        final result = SectionDataResult.allocation(
          allocatedTasks: tasks,
          totalAvailable: 10,
        );

        expect(result, isA<AllocationSectionResult>());
        expect(
          (result as AllocationSectionResult).allocatedTasks,
          hasLength(1),
        );
        expect(result.totalAvailable, 10);
      });

      test('creates with all optional fields', () {
        final tasks = [TestData.task()];
        final pinnedTasks = [
          AllocatedTask(
            task: TestData.task(),
            qualifyingValueId: 'value-1',
            allocationScore: 1,
          ),
        ];
        final result = SectionDataResult.allocation(
          allocatedTasks: tasks,
          totalAvailable: 10,
          pinnedTasks: pinnedTasks,
          displayMode: AllocationDisplayMode.groupedByValue,
        );

        expect((result as AllocationSectionResult).pinnedTasks, hasLength(1));
        expect(result.displayMode, AllocationDisplayMode.groupedByValue);
      });

      group('allTasks', () {
        test('returns allocated tasks', () {
          final tasks = [TestData.task(), TestData.task()];
          final result = SectionDataResult.allocation(
            allocatedTasks: tasks,
            totalAvailable: 10,
          );

          expect(result.allTasks, hasLength(2));
        });
      });

      group('allProjects', () {
        test('returns empty list for allocation results', () {
          final result = SectionDataResult.allocation(
            allocatedTasks: [TestData.task()],
            totalAvailable: 10,
          );

          expect(result.allProjects, isEmpty);
        });
      });

      group('allValues', () {
        test('returns empty list for allocation results', () {
          final result = SectionDataResult.allocation(
            allocatedTasks: [TestData.task()],
            totalAvailable: 10,
          );

          expect(result.allValues, isEmpty);
        });
      });
    });

    group('AgendaSectionResult', () {
      test('creates with required fields', () {
        final today = DateTime.utc(2025, 1, 1);
        final agendaData = AgendaData(
          focusDate: today,
          groups: [
            AgendaDateGroup(
              date: today,
              semanticLabel: 'Today',
              formattedHeader: 'Wed, Jan 1',
              items: [
                AgendaItem(
                  entityType: 'task',
                  entityId: 't1',
                  name: 'Task 1',
                  tag: AgendaDateTag.due,
                  task: TestData.task(id: 't1'),
                ),
              ],
            ),
          ],
        );
        final result = SectionDataResult.agenda(
          agendaData: agendaData,
        );

        expect(result, isA<AgendaSectionResult>());
        expect((result as AgendaSectionResult).agendaData, agendaData);
      });

      group('allTasks', () {
        test('returns all tasks from all groups flattened', () {
          final today = DateTime.utc(2025, 1, 1);
          final tomorrow = DateTime.utc(2025, 1, 2);
          final agendaData = AgendaData(
            focusDate: today,
            groups: [
              AgendaDateGroup(
                date: today,
                semanticLabel: 'Today',
                formattedHeader: 'Wed, Jan 1',
                items: [
                  AgendaItem(
                    entityType: 'task',
                    entityId: 't1',
                    name: 'Task 1',
                    tag: AgendaDateTag.due,
                    task: TestData.task(id: 't1'),
                  ),
                ],
              ),
              AgendaDateGroup(
                date: tomorrow,
                semanticLabel: 'Tomorrow',
                formattedHeader: 'Thu, Jan 2',
                items: [
                  AgendaItem(
                    entityType: 'task',
                    entityId: 't2',
                    name: 'Task 2',
                    tag: AgendaDateTag.due,
                    task: TestData.task(id: 't2'),
                  ),
                  AgendaItem(
                    entityType: 'task',
                    entityId: 't3',
                    name: 'Task 3',
                    tag: AgendaDateTag.due,
                    task: TestData.task(id: 't3'),
                  ),
                ],
              ),
            ],
          );
          final result = SectionDataResult.agenda(
            agendaData: agendaData,
          );

          expect(result.allTasks, hasLength(3));
        });

        test('returns empty list when no groups', () {
          final today = DateTime.utc(2025, 1, 1);
          final result = SectionDataResult.agenda(
            agendaData: AgendaData(focusDate: today, groups: const []),
          );

          expect(result.allTasks, isEmpty);
        });
      });

      group('allProjects', () {
        test('returns empty list for agenda results', () {
          final today = DateTime.utc(2025, 1, 1);
          final result = SectionDataResult.agenda(
            agendaData: AgendaData(focusDate: today, groups: const []),
          );

          expect(result.allProjects, isEmpty);
        });
      });

      group('allValues', () {
        test('returns empty list for agenda results', () {
          final today = DateTime.utc(2025, 1, 1);
          final result = SectionDataResult.agenda(
            agendaData: AgendaData(focusDate: today, groups: const []),
          );

          expect(result.allValues, isEmpty);
        });
      });
    });

    group('AllocationValueGroup', () {
      test('creates with required fields', () {
        final group = AllocationValueGroup(
          valueId: 'value-1',
          valueName: 'Health',
          tasks: [
            AllocatedTask(
              task: TestData.task(),
              qualifyingValueId: 'value-1',
              allocationScore: 1,
            ),
          ],
          weight: 0.5,
          quota: 3,
        );

        expect(group.valueId, 'value-1');
        expect(group.valueName, 'Health');
        expect(group.tasks, hasLength(1));
        expect(group.weight, 0.5);
        expect(group.quota, 3);
      });

      test('creates with optional color', () {
        final group = AllocationValueGroup(
          valueId: 'value-1',
          valueName: 'Health',
          tasks: [],
          weight: 0.5,
          quota: 3,
          color: '#FF0000',
        );

        expect(group.color, '#FF0000');
      });
    });

    group('AllocationDisplayMode', () {
      test('contains all expected values', () {
        expect(
          AllocationDisplayMode.values,
          contains(AllocationDisplayMode.flat),
        );
        expect(
          AllocationDisplayMode.values,
          contains(AllocationDisplayMode.groupedByValue),
        );
        expect(
          AllocationDisplayMode.values,
          contains(AllocationDisplayMode.pinnedFirst),
        );
      });
    });
  });
}

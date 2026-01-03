import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';

import '../../../fixtures/test_data.dart';

void main() {
  group('SectionDataResult', () {
    group('DataSectionResult', () {
      test('creates with required fields', () {
        final result = SectionDataResult.data(
          primaryEntities: [TestData.task()],
          primaryEntityType: 'task',
        );

        expect(result, isA<DataSectionResult>());
        final dataResult = result as DataSectionResult;
        expect(dataResult.primaryEntityType, 'task');
        expect(dataResult.primaryEntities, hasLength(1));
      });

      test('creates with related entities', () {
        final result = SectionDataResult.data(
          primaryEntities: [TestData.task()],
          primaryEntityType: 'task',
          relatedEntities: {
            'projects': [TestData.project()],
          },
        );

        final dataResult = result as DataSectionResult;
        expect(dataResult.relatedEntities['projects'], hasLength(1));
      });

      group('allTasks', () {
        test('returns tasks when primaryEntityType is task', () {
          final tasks = [TestData.task(), TestData.task()];
          final result = SectionDataResult.data(
            primaryEntities: tasks,
            primaryEntityType: 'task',
          );

          expect(result.allTasks, hasLength(2));
        });

        test('returns empty list when primaryEntityType is not task', () {
          final result = SectionDataResult.data(
            primaryEntities: [TestData.project()],
            primaryEntityType: 'project',
          );

          expect(result.allTasks, isEmpty);
        });
      });

      group('allProjects', () {
        test('returns projects when primaryEntityType is project', () {
          final projects = [TestData.project(), TestData.project()];
          final result = SectionDataResult.data(
            primaryEntities: projects,
            primaryEntityType: 'project',
          );

          expect(result.allProjects, hasLength(2));
        });

        test('returns empty list when primaryEntityType is not project', () {
          final result = SectionDataResult.data(
            primaryEntities: [TestData.task()],
            primaryEntityType: 'task',
          );

          expect(result.allProjects, isEmpty);
        });
      });

      group('allLabels', () {
        test('returns labels when primaryEntityType is label', () {
          final labels = [TestData.label(), TestData.label()];
          final result = SectionDataResult.data(
            primaryEntities: labels,
            primaryEntityType: 'label',
          );

          expect(result.allLabels, hasLength(2));
        });

        test('returns labels when primaryEntityType is value', () {
          final labels = [
            TestData.label(type: LabelType.value),
          ];
          final result = SectionDataResult.data(
            primaryEntities: labels,
            primaryEntityType: 'value',
          );

          expect(result.allLabels, hasLength(1));
        });

        test(
          'returns empty list when primaryEntityType is not label/value',
          () {
            final result = SectionDataResult.data(
              primaryEntities: [TestData.task()],
              primaryEntityType: 'task',
            );

            expect(result.allLabels, isEmpty);
          },
        );
      });

      group('relatedTasks', () {
        test('returns related tasks from relatedEntities', () {
          final result = SectionDataResult.data(
            primaryEntities: [TestData.project()],
            primaryEntityType: 'project',
            relatedEntities: {
              'tasks': <Task>[TestData.task(), TestData.task()],
            },
          );

          expect(result.relatedTasks, hasLength(2));
        });

        test('returns empty list when no related tasks', () {
          final result = SectionDataResult.data(
            primaryEntities: [TestData.project()],
            primaryEntityType: 'project',
          );

          expect(result.relatedTasks, isEmpty);
        });
      });

      group('relatedProjects', () {
        test('returns related projects from relatedEntities', () {
          final result = SectionDataResult.data(
            primaryEntities: [TestData.task()],
            primaryEntityType: 'task',
            relatedEntities: {
              'projects': <Project>[TestData.project()],
            },
          );

          expect(result.relatedProjects, hasLength(1));
        });

        test('returns empty list when no related projects', () {
          final result = SectionDataResult.data(
            primaryEntities: [TestData.task()],
            primaryEntityType: 'task',
          );

          expect(result.relatedProjects, isEmpty);
        });
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
          excludedCount: 5,
          displayMode: AllocationDisplayMode.groupedByValue,
        );

        expect((result as AllocationSectionResult).pinnedTasks, hasLength(1));
        expect(result.excludedCount, 5);
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

      group('allLabels', () {
        test('returns empty list for allocation results', () {
          final result = SectionDataResult.allocation(
            allocatedTasks: [TestData.task()],
            totalAvailable: 10,
          );

          expect(result.allLabels, isEmpty);
        });
      });

      group('relatedTasks', () {
        test('returns empty list for allocation results', () {
          final result = SectionDataResult.allocation(
            allocatedTasks: [TestData.task()],
            totalAvailable: 10,
          );

          expect(result.relatedTasks, isEmpty);
        });
      });

      group('relatedProjects', () {
        test('returns empty list for allocation results', () {
          final result = SectionDataResult.allocation(
            allocatedTasks: [TestData.task()],
            totalAvailable: 10,
          );

          expect(result.relatedProjects, isEmpty);
        });
      });
    });

    group('AgendaSectionResult', () {
      test('creates with required fields', () {
        final result = SectionDataResult.agenda(
          groupedTasks: {
            'today': [TestData.task()],
            'tomorrow': [TestData.task(), TestData.task()],
          },
          groupOrder: ['today', 'tomorrow'],
        );

        expect(result, isA<AgendaSectionResult>());
        expect(
          (result as AgendaSectionResult).groupedTasks['today'],
          hasLength(1),
        );
        expect(result.groupOrder, ['today', 'tomorrow']);
      });

      group('allTasks', () {
        test('returns all tasks from all groups flattened', () {
          final result = SectionDataResult.agenda(
            groupedTasks: {
              'today': [TestData.task()],
              'tomorrow': [TestData.task(), TestData.task()],
            },
            groupOrder: ['today', 'tomorrow'],
          );

          expect(result.allTasks, hasLength(3));
        });

        test('returns empty list when no groups', () {
          final result = SectionDataResult.agenda(
            groupedTasks: {},
            groupOrder: [],
          );

          expect(result.allTasks, isEmpty);
        });
      });

      group('allProjects', () {
        test('returns empty list for agenda results', () {
          final result = SectionDataResult.agenda(
            groupedTasks: {
              'today': [TestData.task()],
            },
            groupOrder: ['today'],
          );

          expect(result.allProjects, isEmpty);
        });
      });

      group('allLabels', () {
        test('returns empty list for agenda results', () {
          final result = SectionDataResult.agenda(
            groupedTasks: {
              'today': [TestData.task()],
            },
            groupOrder: ['today'],
          );

          expect(result.allLabels, isEmpty);
        });
      });

      group('relatedTasks', () {
        test('returns empty list for agenda results', () {
          final result = SectionDataResult.agenda(
            groupedTasks: {
              'today': [TestData.task()],
            },
            groupOrder: ['today'],
          );

          expect(result.relatedTasks, isEmpty);
        });
      });

      group('relatedProjects', () {
        test('returns empty list for agenda results', () {
          final result = SectionDataResult.agenda(
            groupedTasks: {
              'today': [TestData.task()],
            },
            groupOrder: ['today'],
          );

          expect(result.relatedProjects, isEmpty);
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

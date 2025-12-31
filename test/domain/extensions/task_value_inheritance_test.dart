import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/extensions/task_value_inheritance.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/task.dart';

import '../../fixtures/test_data.dart';

void main() {
  group('TaskValueInheritance', () {
    late Label valueHealth;
    late Label valueFamily;
    late Label valueWork;
    late Label labelCategory;

    setUp(() {
      final now = DateTime(2024);

      valueHealth = TestData.label(
        id: 'value-health',
        name: 'Health',
        color: '#FF0000',
        type: LabelType.value,
        createdAt: now,
        updatedAt: now,
      );

      valueFamily = TestData.label(
        id: 'value-family',
        name: 'Family',
        color: '#00FF00',
        type: LabelType.value,
        createdAt: now,
        updatedAt: now,
      );

      valueWork = TestData.label(
        id: 'value-work',
        name: 'Work',
        color: '#0000FF',
        type: LabelType.value,
        createdAt: now,
        updatedAt: now,
      );

      labelCategory = TestData.label(
        id: 'label-urgent',
        name: 'Urgent',
        color: '#FFFF00',
        createdAt: now,
        updatedAt: now,
      );
    });

    test('getEffectiveValues returns only task values when no project', () {
      final now = DateTime(2024);
      final task = TestData.task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        labels: [valueWork, labelCategory],
      );

      final effectiveValues = task.getEffectiveValues();

      expect(effectiveValues.length, 1);
      expect(effectiveValues.first.id, 'value-work');
    });

    test('getEffectiveValues combines task and project values additively', () {
      final now = DateTime(2024);
      final project = TestData.project(
        id: 'p1',
        name: 'Health Project',
        createdAt: now,
        updatedAt: now,
        labels: [valueHealth, valueFamily],
      );

      final task = TestData.task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        labels: [valueWork],
        project: project,
        projectId: project.id,
      );

      final effectiveValues = task.getEffectiveValues();

      expect(effectiveValues.length, 3);
      expect(effectiveValues.map((v) => v.id).toSet(), {
        'value-work',
        'value-health',
        'value-family',
      });
    });

    test(
      'getEffectiveValues removes duplicates when task has same value as project',
      () {
        final now = DateTime(2024);
        final project = TestData.project(
          id: 'p1',
          name: 'Health Project',
          createdAt: now,
          updatedAt: now,
          labels: [valueHealth, valueFamily],
        );

        final task = TestData.task(
          id: 't1',
          createdAt: now,
          updatedAt: now,
          labels: [valueHealth, valueWork], // Health is duplicate
          project: project,
          projectId: project.id,
        );

        final effectiveValues = task.getEffectiveValues();

        expect(effectiveValues.length, 3);
        // Should have Health (from task), Work (from task), Family (from project)
        expect(effectiveValues.where((v) => v.id == 'value-health').length, 1);
      },
    );

    test('getEffectiveValues excludes non-value labels', () {
      final now = DateTime(2024);
      final project = TestData.project(
        id: 'p1',
        createdAt: now,
        updatedAt: now,
        labels: [valueHealth, labelCategory], // Has both value and label
      );

      final task = TestData.task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        labels: [valueWork, labelCategory],
        project: project,
        projectId: project.id,
      );

      final effectiveValues = task.getEffectiveValues();

      expect(effectiveValues.length, 2);
      expect(effectiveValues.every((l) => l.type == LabelType.value), true);
      expect(effectiveValues.map((v) => v.id).toSet(), {
        'value-work',
        'value-health',
      });
    });

    test('getDirectValues returns only task values, not inherited', () {
      final now = DateTime(2024);
      final project = TestData.project(
        id: 'p1',
        createdAt: now,
        updatedAt: now,
        labels: [valueHealth, valueFamily],
      );

      final task = TestData.task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        labels: [valueWork],
        project: project,
        projectId: project.id,
      );

      final directValues = task.getDirectValues();

      expect(directValues.length, 1);
      expect(directValues.first.id, 'value-work');
    });

    test('getInheritedValues returns only project values not on task', () {
      final now = DateTime(2024);
      final project = TestData.project(
        id: 'p1',
        createdAt: now,
        updatedAt: now,
        labels: [valueHealth, valueFamily],
      );

      final task = TestData.task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        labels: [valueWork],
        project: project,
        projectId: project.id,
      );

      final inheritedValues = task.getInheritedValues();

      expect(inheritedValues.length, 2);
      expect(inheritedValues.map((v) => v.id).toSet(), {
        'value-health',
        'value-family',
      });
    });

    test('getInheritedValues excludes values already on task', () {
      final now = DateTime(2024);
      final project = TestData.project(
        id: 'p1',
        createdAt: now,
        updatedAt: now,
        labels: [valueHealth, valueFamily, valueWork],
      );

      final task = TestData.task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        labels: [valueWork], // Work is on both task and project
        project: project,
        projectId: project.id,
      );

      final inheritedValues = task.getInheritedValues();

      expect(inheritedValues.length, 2);
      expect(inheritedValues.map((v) => v.id).toSet(), {
        'value-health',
        'value-family',
      });
    });

    test('isValueInherited returns true for inherited value', () {
      final now = DateTime(2024);
      final project = TestData.project(
        id: 'p1',
        createdAt: now,
        updatedAt: now,
        labels: [valueHealth],
      );

      final task = TestData.task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        labels: [valueWork],
        project: project,
        projectId: project.id,
      );

      expect(task.isValueInherited('value-health'), true);
      expect(task.isValueInherited('value-work'), false);
      expect(task.isValueInherited('value-family'), false);
    });

    test('handles empty project labels', () {
      final now = DateTime(2024);
      final project = TestData.project(
        id: 'p1',
        name: 'Empty Project',
        createdAt: now,
        updatedAt: now,
      );

      final task = TestData.task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        labels: [valueWork],
        project: project,
        projectId: project.id,
      );

      final effectiveValues = task.getEffectiveValues();
      expect(effectiveValues.length, 1);
      expect(effectiveValues.first.id, 'value-work');

      final inheritedValues = task.getInheritedValues();
      expect(inheritedValues, isEmpty);
    });

    test('handles empty task labels with project values', () {
      final now = DateTime(2024);
      final project = TestData.project(
        id: 'p1',
        createdAt: now,
        updatedAt: now,
        labels: [valueHealth, valueFamily],
      );

      final task = TestData.task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        project: project,
        projectId: project.id,
      );

      final effectiveValues = task.getEffectiveValues();
      expect(effectiveValues.length, 2);
      expect(effectiveValues.map((v) => v.id).toSet(), {
        'value-health',
        'value-family',
      });

      final directValues = task.getDirectValues();
      expect(directValues, isEmpty);

      final inheritedValues = task.getInheritedValues();
      expect(inheritedValues.length, 2);
    });
  });
}

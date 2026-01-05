import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/allocation_section_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/value_balance_chart.dart';
import 'package:taskly_bloc/domain/models/task.dart';

void main() {
  group('AllocationSectionRenderer', () {
    testWidgets('renders ValueBalanceChart when persona is reflector', (
      tester,
    ) async {
      final data = AllocationSectionResult(
        allocatedTasks: [
          Task(
            id: '1',
            name: 'Test Task',
            completed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        totalAvailable: 1,
        activePersona: AllocationPersona.reflector,
        tasksByValue: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationSectionRenderer(data: data),
            ),
          ),
        ),
      );

      expect(find.byType(ValueBalanceChart), findsOneWidget);
    });

    testWidgets(
      'does not render ValueBalanceChart when persona is not reflector',
      (tester) async {
        final data = AllocationSectionResult(
          allocatedTasks: [
            Task(
              id: '1',
              name: 'Test Task',
              completed: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          totalAvailable: 1,
          activePersona: AllocationPersona.realist,
          tasksByValue: {},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AllocationSectionRenderer(data: data),
              ),
            ),
          ),
        );

        expect(find.byType(ValueBalanceChart), findsNothing);
      },
    );
  });
}

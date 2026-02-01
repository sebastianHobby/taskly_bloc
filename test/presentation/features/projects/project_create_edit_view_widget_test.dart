@Tags(['widget', 'projects'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/presentation_mocks.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_create_edit_view.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_form.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/core.dart';

class MockProjectDetailBloc
    extends MockBloc<ProjectDetailEvent, ProjectDetailState>
    implements ProjectDetailBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockProjectDetailBloc bloc;
  late MockNowService nowService;

  setUp(() {
    bloc = MockProjectDetailBloc();
    nowService = MockNowService();
    when(() => nowService.nowLocal()).thenReturn(DateTime(2025, 1, 15, 9));
    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15, 9));
  });

  Future<void> pumpView(WidgetTester tester, Widget child) async {
    await tester.pumpWidgetWithBloc<ProjectDetailBloc>(
      bloc: bloc,
      child: RepositoryProvider<NowService>.value(
        value: nowService,
        child: child,
      ),
    );
  }

  testWidgetsSafe('shows loading indicator while loading', (tester) async {
    const state = ProjectDetailState.loadInProgress();
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(tester, const ProjectEditSheetView());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('renders project form for create flow', (tester) async {
    final value = TestData.value(name: 'Focus');
    final state = ProjectDetailState.initialDataLoadSuccess(
      availableValues: [value],
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(tester, const ProjectEditSheetView());

    expect(find.byType(ProjectForm), findsOneWidget);
  });

  testWidgetsSafe('renders project form for edit flow', (tester) async {
    final project = TestData.project(name: 'Project X');
    final state = ProjectDetailState.loadSuccess(
      availableValues: const <Value>[],
      project: project,
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(tester, const ProjectEditSheetView(projectId: 'project-1'));

    expect(find.byType(ProjectForm), findsOneWidget);
    expect(find.text('Project X'), findsOneWidget);
  });
}

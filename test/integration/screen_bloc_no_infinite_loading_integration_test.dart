/// Regression tests for "infinite loading" screens.
///
/// These tests are designed to fail fast (via explicit timeouts) if a screen
/// load never completes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/screen_chrome.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section_ref.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter_registry.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_params_codec.dart';
import 'package:taskly_bloc/domain/services/screens/templates/static_section_interpreter.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';

import '../helpers/integration_test_helpers.dart';

void main() {
  group('ScreenBloc (integration) infinite loading guards', () {
    late IntegrationTestContext ctx;

    setUp(() async {
      ctx = await IntegrationTestContext.create();
    });

    tearDown(() async {
      await ctx.dispose();
    });

    testIntegration(
      'loadById reaches loaded state quickly for a minimal custom screen',
      () async {
        const screenKey = 'test-static-screen';

        // Minimal custom screen with a template that emits immediately.
        final screen = ScreenDefinition(
          id: '',
          screenKey: screenKey,
          name: 'Test Static Screen',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          chrome: const ScreenChrome(iconName: 'test'),
          sections: const [
            SectionRef(templateId: SectionTemplateId.settingsMenu),
          ],
        );

        await ctx.seedScreen(screen: screen);

        final interpreter = ScreenDataInterpreter(
          interpreterRegistry: SectionTemplateInterpreterRegistry([
            StaticSectionInterpreter(
              templateId: SectionTemplateId.settingsMenu,
            ),
          ]),
          paramsCodec: SectionTemplateParamsCodec(),
        );

        final bloc = ctx.trackBloc(
          ScreenBloc(
            screenRepository: ctx.screensRepository,
            interpreter: interpreter,
          ),
        );

        bloc.add(const ScreenEvent.loadById(screenId: screenKey));

        await expectBlocState<ScreenState>(
          bloc,
          (s) => s is ScreenLoadedState,
          timeout: const Duration(seconds: 2),
          reason: 'Screen stayed in loading too long (possible infinite load).',
        );
      },
      timeout: const Duration(seconds: 10),
    );
  });
}

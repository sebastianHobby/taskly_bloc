import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_state.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';
import 'package:taskly_bloc/presentation/screens/templates/screen_template_widget.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/section_renderer_registry.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

/// Unified page for rendering typed [ScreenSpec] system screens.
class UnifiedScreenPageFromSpec extends StatelessWidget {
  const UnifiedScreenPageFromSpec({
    required this.spec,
    super.key,
  });

  final ScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SectionRendererRegistry>(
          create: (_) => const DefaultSectionRendererRegistry(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ScreenSpecBloc(
              interpreter: getIt<ScreenSpecDataInterpreter>(),
            )..add(ScreenSpecLoadEvent(spec: spec)),
          ),
          BlocProvider(
            create: (_) => ScreenActionsBloc(
              entityActionService: getIt<EntityActionService>(),
            ),
          ),
        ],
        child: const _UnifiedScreenSpecBody(),
      ),
    );
  }
}

class _UnifiedScreenSpecBody extends StatelessWidget {
  const _UnifiedScreenSpecBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScreenActionsBloc, ScreenActionsState>(
      listenWhen: (previous, current) => current is ScreenActionsFailureState,
      listener: (context, state) {
        if (state is! ScreenActionsFailureState) return;

        final message = state.error == null
            ? state.message
            : friendlyErrorMessageForUi(state.error!, context.l10n);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      child: BlocBuilder<ScreenSpecBloc, ScreenSpecState>(
        builder: (context, state) {
          return switch (state) {
            ScreenSpecInitialState() ||
            ScreenSpecLoadingState() => const Center(
              child: CircularProgressIndicator(),
            ),
            ScreenSpecLoadedState(:final data) => ScreenTemplateWidget(
              data: data,
            ),
            ScreenSpecErrorState(:final message) => Center(
              child: Text(message),
            ),
          };
        },
      ),
    );
  }
}

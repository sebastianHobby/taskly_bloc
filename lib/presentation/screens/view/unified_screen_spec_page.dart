import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_state.dart';
import 'package:taskly_bloc/presentation/screens/templates/screen_template_widget.dart';

/// Unified page for rendering typed [ScreenSpec] system screens.
class UnifiedScreenPageFromSpec extends StatelessWidget {
  const UnifiedScreenPageFromSpec({
    required this.spec,
    super.key,
  });

  final ScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScreenSpecBloc(
        interpreter: getIt<ScreenSpecDataInterpreter>(),
      )..add(ScreenSpecLoadEvent(spec: spec)),
      child: const _UnifiedScreenSpecBody(),
    );
  }
}

class _UnifiedScreenSpecBody extends StatelessWidget {
  const _UnifiedScreenSpecBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenSpecBloc, ScreenSpecState>(
      builder: (context, state) {
        return switch (state) {
          ScreenSpecInitialState() || ScreenSpecLoadingState() => const Center(
            child: CircularProgressIndicator(),
          ),
          ScreenSpecLoadedState(:final data) => ScreenTemplateWidget(
            data: data,
          ),
          ScreenSpecErrorState(:final message) => Center(child: Text(message)),
        };
      },
    );
  }
}

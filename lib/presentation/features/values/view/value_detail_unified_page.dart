import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/screens/catalog/entity_screens/entity_detail_screen_specs.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_detail_bloc.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_state.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/loading_state_widget.dart';
import 'package:taskly_bloc/presentation/screens/templates/screen_template_widget.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/section_renderer_registry.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_banner_session_cubit.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_bell_cubit.dart';

/// Unified value detail page using the screen model.
///
/// Fetches the value first, then creates a typed [ScreenSpec]
/// and renders using the unified pattern.
class ValueDetailUnifiedPage extends StatelessWidget {
  const ValueDetailUnifiedPage({
    required this.valueId,
    super.key,
  });

  final String valueId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ValueDetailBloc>(
      create: (_) => ValueDetailBloc(
        valueRepository: getIt<ValueRepositoryContract>(),
        valueId: valueId,
      ),
      child: _ValueDetailContent(valueId: valueId),
    );
  }
}

class _ValueDetailContent extends StatelessWidget {
  const _ValueDetailContent({required this.valueId});

  final String valueId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ValueDetailBloc, ValueDetailState>(
      builder: (context, state) {
        return switch (state) {
          ValueDetailInitial() ||
          ValueDetailLoadInProgress() => const _LoadingScaffold(),
          ValueDetailLoadSuccess(:final value) => _ValueScreenWithData(
            value: value,
          ),
          ValueDetailOperationFailure(:final errorDetails) => _ErrorScaffold(
            message: friendlyErrorMessageForUi(
              errorDetails.error,
              context.l10n,
            ),
            onRetry: () => context.read<ValueDetailBloc>().add(
              ValueDetailEvent.loadById(valueId: valueId),
            ),
          ),
          _ => const _LoadingScaffold(),
        };
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.loadingTitle)),
      body: const LoadingStateWidget(),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.errorTitle)),
      body: ErrorStateWidget(message: message, onRetry: onRetry),
    );
  }
}

/// Main content view when value is loaded
class _ValueScreenWithData extends StatelessWidget {
  const _ValueScreenWithData({required this.value});

  final Value value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spec = EntityDetailScreenSpecs.valueDetail(
      value: value,
      projectsAndTasksTitle: l10n.valueDetailProjectsAndTasksSectionTitle,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SectionRendererRegistry>(
          create: (_) => const DefaultSectionRendererRegistry(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ScreenSpecBloc>(
            create: (_) => ScreenSpecBloc(
              interpreter: getIt<ScreenSpecDataInterpreter>(),
              attentionBellCubit: getIt<AttentionBellCubit>(),
              attentionBannerSessionCubit: getIt<AttentionBannerSessionCubit>(),
            )..add(ScreenSpecLoadEvent(spec: spec)),
          ),
        ],
        child: BlocListener<ScreenSpecBloc, ScreenSpecState>(
          listenWhen: (previous, current) {
            return previous is! ScreenSpecLoadedState &&
                current is ScreenSpecLoadedState;
          },
          listener: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              getIt<PerformanceLogger>().markFirstPaint();
            });
          },
          child: BlocBuilder<ScreenSpecBloc, ScreenSpecState>(
            builder: (context, state) {
              return switch (state) {
                ScreenSpecInitialState() ||
                ScreenSpecLoadingState() => const LoadingStateWidget(),
                ScreenSpecLoadedState(
                  :final data,
                  :final attentionSessionBanner,
                ) =>
                  ScreenTemplateWidget(
                    data: data,
                    attentionSessionBanner: attentionSessionBanner,
                  ),
                ScreenSpecErrorState(:final message) => ErrorStateWidget(
                  message: message,
                  onRetry: () => Navigator.of(context).pop(),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

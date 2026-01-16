import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_state.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/loading_state_widget.dart';
import 'package:taskly_bloc/presentation/screens/templates/screen_template_widget.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/section_renderer_registry.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_banner_session_cubit.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_bell_cubit.dart';

/// Unified project detail page using the screen model.
///
/// Fetches the project first, then creates a typed [ScreenSpec]
/// and renders using the unified pattern.
class ProjectDetailUnifiedPage extends StatelessWidget {
  const ProjectDetailUnifiedPage({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProjectDetailBloc>(
      create: (_) => ProjectDetailBloc(
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
      )..add(ProjectDetailEvent.loadById(projectId: projectId)),
      child: _ProjectDetailContent(projectId: projectId),
    );
  }
}

class _ProjectDetailContent extends StatelessWidget {
  const _ProjectDetailContent({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectDetailBloc, ProjectDetailState>(
      builder: (context, state) {
        return switch (state) {
          ProjectDetailInitial() ||
          ProjectDetailLoadInProgress() => const _LoadingScaffold(),
          ProjectDetailLoadSuccess(:final project) => _ProjectScreenWithData(
            project: project,
          ),
          ProjectDetailOperationFailure(:final errorDetails) => _ErrorScaffold(
            message: friendlyErrorMessageForUi(
              errorDetails.error,
              context.l10n,
            ),
            onRetry: () => context.read<ProjectDetailBloc>().add(
              ProjectDetailEvent.loadById(projectId: projectId),
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

/// Main content view when project is loaded
class _ProjectScreenWithData extends StatelessWidget {
  const _ProjectScreenWithData({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spec = ScreenSpec(
      id: 'project_${project.id}',
      screenKey: 'project_detail',
      name: project.name,
      template: const ScreenTemplateSpec.entityDetailScaffoldV1(),
      modules: SlottedModules(
        header: [
          ScreenModuleSpec.entityHeader(
            params: EntityHeaderSectionParams(
              entityType: 'project',
              entityId: project.id,
              showCheckbox: true,
              showMetadata: true,
            ),
          ),
        ],
        primary: [
          ScreenModuleSpec.taskListV2(
            title: l10n.tasksTitle,
            params: ListSectionParamsV2(
              config: DataConfig.task(
                query: TaskQuery.forProject(projectId: project.id),
              ),
              separator: ListSeparatorV2.divider,
            ),
          ),
        ],
      ),
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
          BlocProvider<ScreenActionsBloc>(
            create: (_) => ScreenActionsBloc(
              entityActionService: getIt<EntityActionService>(),
            ),
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

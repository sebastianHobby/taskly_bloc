import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_scope_picker_bloc.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class AnytimeScopePickerSheet {
  static Future<AnytimeScope?> show(
    BuildContext context,
    AnytimeScope? currentScope,
  ) {
    return showModalBottomSheet<AnytimeScope?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return BlocProvider(
          create: (context) => AnytimeScopePickerBloc(
            sharedDataService: context.read<SessionSharedDataService>(),
          ),
          child: _AnytimeScopePickerView(currentScope: currentScope),
        );
      },
    );
  }
}

class _AnytimeScopePickerView extends StatefulWidget {
  const _AnytimeScopePickerView({required this.currentScope});

  final AnytimeScope? currentScope;

  @override
  State<_AnytimeScopePickerView> createState() =>
      _AnytimeScopePickerViewState();
}

class _AnytimeScopePickerViewState extends State<_AnytimeScopePickerView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentScope = widget.currentScope;
    final tokens = TasklyTokens.of(context);

    final currentValueId = switch (currentScope) {
      AnytimeValueScope(:final valueId) => valueId,
      _ => null,
    };

    final currentProjectId = switch (currentScope) {
      AnytimeProjectScope(:final projectId) => projectId,
      _ => null,
    };

    final isAllSelected = currentScope == null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: tokens.spaceLg,
          top: tokens.spaceMd,
          right: tokens.spaceLg,
          bottom: tokens.spaceXl + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.anytimeScopePickerTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.closeLabel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.anytimeScopePickerSearchHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            Expanded(
              child:
                  BlocBuilder<AnytimeScopePickerBloc, AnytimeScopePickerState>(
                    builder: (context, state) {
                      return switch (state) {
                        AnytimeScopePickerLoading() => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        AnytimeScopePickerError(:final message) => _ErrorView(
                          message: message,
                          onRetry: () =>
                              context.read<AnytimeScopePickerBloc>().add(
                                const AnytimeScopePickerRetryRequested(),
                              ),
                        ),
                        AnytimeScopePickerLoaded(
                          :final values,
                          :final projects,
                        ) =>
                          _LoadedView(
                            values: values,
                            projects: projects,
                            searchQuery: _searchController.text.trim(),
                            isAllSelected: isAllSelected,
                            currentValueId: currentValueId,
                            currentProjectId: currentProjectId,
                          ),
                      };
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(l10n.retryButton),
        ),
      ],
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.values,
    required this.projects,
    required this.searchQuery,
    required this.isAllSelected,
    required this.currentValueId,
    required this.currentProjectId,
  });

  final List<Value> values;
  final List<Project> projects;
  final String searchQuery;
  final bool isAllSelected;
  final String? currentValueId;
  final String? currentProjectId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = searchQuery.toLowerCase();

    final filteredValues = q.isEmpty
        ? values
        : values
              .where((v) => v.name.trim().toLowerCase().contains(q))
              .toList(growable: false);

    final filteredProjects = q.isEmpty
        ? projects
        : projects
              .where((p) => p.name.trim().toLowerCase().contains(q))
              .toList(growable: false);

    final hasMatches =
        q.isEmpty || filteredValues.isNotEmpty || filteredProjects.isNotEmpty;

    return ListView(
      children: [
        ListTile(
          title: Text(l10n.allLabel),
          trailing: isAllSelected ? const Icon(Icons.check) : null,
          onTap: () => Navigator.of(context).pop<AnytimeScope?>(null),
        ),
        if (!hasMatches) ...[
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          _InlineEmptyMessage(
            title: l10n.anytimeScopePickerNoMatchesTitle,
            body: l10n.anytimeScopePickerNoMatchesBody,
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
        ],
        _SectionHeader(l10n.valuesTitle),
        if (q.isEmpty && values.isEmpty)
          _InlineEmptyMessage(
            title: l10n.anytimeScopePickerNoValuesTitle,
            body: l10n.anytimeScopePickerNoValuesBody,
          )
        else
          for (final v in filteredValues)
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: Text(v.name),
              trailing: v.id == currentValueId ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop<AnytimeScope?>(
                AnytimeScope.value(valueId: v.id),
              ),
            ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        _SectionHeader(l10n.projectsTitle),
        if (q.isEmpty && projects.isEmpty)
          _InlineEmptyMessage(
            title: l10n.anytimeScopePickerNoProjectsTitle,
            body: l10n.anytimeScopePickerNoProjectsBody,
          )
        else
          for (final p in filteredProjects)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(p.name),
              trailing: p.id == currentProjectId
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(context).pop<AnytimeScope?>(
                AnytimeScope.project(projectId: p.id),
              ),
            ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceXs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

class _InlineEmptyMessage extends StatelessWidget {
  const _InlineEmptyMessage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

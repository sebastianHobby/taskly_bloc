import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/project_picker/bloc/project_picker_bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

typedef ProjectPickerOnSelect = Future<void> Function(String? projectId);

Future<void> showProjectPickerModal({
  required BuildContext context,
  required ProjectRepositoryContract projectRepository,
  required ProjectPickerOnSelect onSelect,
}) async {
  final media = MediaQuery.of(context);
  final useSheet = media.size.width < 600;

  if (useSheet) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final height = media.size.height * 0.85;

        return SafeArea(
          child: SizedBox(
            height: height,
            child: _ProjectPickerScaffold(
              projectRepository: projectRepository,
              onSelect: onSelect,
              isDialog: false,
            ),
          ),
        );
      },
    );
  }

  // Desktop/tablet: dialog is usually more ergonomic.
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: _ProjectPickerScaffold(
            projectRepository: projectRepository,
            onSelect: onSelect,
            isDialog: true,
          ),
        ),
      );
    },
  );
}

class _ProjectPickerScaffold extends StatelessWidget {
  const _ProjectPickerScaffold({
    required this.projectRepository,
    required this.onSelect,
    required this.isDialog,
  });

  final ProjectRepositoryContract projectRepository;
  final ProjectPickerOnSelect onSelect;
  final bool isDialog;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final content = Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: BlocProvider<ProjectPickerBloc>(
        create: (_) =>
            ProjectPickerBloc(projectRepository: projectRepository)
              ..add(const ProjectPickerStarted()),
        child: _ProjectPickerBody(onSelect: onSelect, isDialog: isDialog),
      ),
    );

    if (!isDialog) return content;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.l10n.selectProjectTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.closeLabel,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: content,
    );
  }
}

class _ProjectPickerBody extends StatefulWidget {
  const _ProjectPickerBody({
    required this.onSelect,
    required this.isDialog,
  });

  final ProjectPickerOnSelect onSelect;
  final bool isDialog;

  @override
  State<_ProjectPickerBody> createState() => _ProjectPickerBodyState();
}

class _ProjectPickerBodyState extends State<_ProjectPickerBody> {
  bool _isSubmitting = false;
  Object? _selectionError;

  Future<void> _handleSelect(String? projectId) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _selectionError = null;
    });

    try {
      await widget.onSelect(projectId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _selectionError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final header = widget.isDialog
        ? SizedBox.shrink()
        : Padding(
            padding: EdgeInsets.fromLTRB(
              TasklyTokens.of(context).spaceLg,
              TasklyTokens.of(context).spaceSm,
              TasklyTokens.of(context).spaceLg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.selectProjectTitle,
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
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        Padding(
          padding: EdgeInsets.fromLTRB(
            TasklyTokens.of(context).spaceLg,
            TasklyTokens.of(context).spaceSm,
            TasklyTokens.of(context).spaceLg,
            TasklyTokens.of(context).spaceSm,
          ),
          child: TextField(
            enabled: !_isSubmitting,
            onChanged: (value) => context.read<ProjectPickerBloc>().add(
              ProjectPickerSearchChanged(query: value),
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.projectPickerSearchHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        if (_selectionError != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              TasklyTokens.of(context).spaceLg,
              0,
              TasklyTokens.of(context).spaceLg,
              TasklyTokens.of(context).spaceSm,
            ),
            child: MaterialBanner(
              content: Text(l10n.genericErrorFallback),
              leading: const Icon(Icons.error_outline),
              actions: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() => _selectionError = null);
                        },
                  child: Text(l10n.closeLabel),
                ),
              ],
            ),
          ),
        Expanded(
          child: BlocBuilder<ProjectPickerBloc, ProjectPickerState>(
            builder: (context, state) {
              return Column(
                children: [
                  if (state.hasLoadError)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        TasklyTokens.of(context).spaceLg,
                        0,
                        TasklyTokens.of(context).spaceLg,
                        TasklyTokens.of(context).spaceSm,
                      ),
                      child: MaterialBanner(
                        content: Text(l10n.genericErrorFallback),
                        leading: const Icon(Icons.wifi_off_outlined),
                        actions: [
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => context.read<ProjectPickerBloc>().add(
                                    const ProjectPickerRetryRequested(),
                                  ),
                            child: Text(l10n.retryButton),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: switch ((state.isLoading, state.visibleProjects)) {
                      (true, []) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      (_, final projects) when projects.isEmpty => Center(
                        child: Padding(
                          padding: EdgeInsets.all(
                            TasklyTokens.of(context).spaceLg,
                          ),
                          child: Text(
                            l10n.projectPickerNoMatchingProjects,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      (_, final projects) => ListView.builder(
                        itemCount: projects.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ListTile(
                              enabled: !_isSubmitting,
                              leading: const Icon(Icons.folder_off_outlined),
                              title: Text(l10n.projectPickerNoProjectInbox),
                              onTap: () => _handleSelect(null),
                            );
                          }

                          final project = projects[index - 1];
                          return ListTile(
                            enabled: !_isSubmitting,
                            leading: const Icon(Icons.folder_outlined),
                            title: Text(project.name),
                            trailing: project.completed
                                ? const Icon(Icons.check_circle_outline)
                                : null,
                            onTap: () => _handleSelect(project.id),
                          );
                        },
                      ),
                    },
                  ),
                ],
              );
            },
          ),
        ),
        if (kIsWeb) SizedBox(height: TasklyTokens.of(context).spaceSm),
      ],
    );
  }
}

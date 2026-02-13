import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/debouncer.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_bloc/presentation/widgets/pickers/picker_shell.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

sealed class ProjectPickerResult {
  const ProjectPickerResult();
}

final class ProjectPickerResultSelected extends ProjectPickerResult {
  const ProjectPickerResultSelected(this.project);
  final Project project;
}

final class ProjectPickerResultCleared extends ProjectPickerResult {
  const ProjectPickerResultCleared();
}

class ProjectPickerContent extends StatefulWidget {
  const ProjectPickerContent({
    required this.availableProjects,
    required this.recentProjectIds,
    this.currentProjectId,
    this.allowNoProject = true,
    super.key,
  });

  final List<Project> availableProjects;
  final List<String> recentProjectIds;
  final String? currentProjectId;
  final bool allowNoProject;

  @override
  State<ProjectPickerContent> createState() => _ProjectPickerContentState();
}

class _ProjectPickerContentState extends State<ProjectPickerContent> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(_searchDebounce);

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final currentId = (widget.currentProjectId ?? '').trim();
    final query = _searchController.text.trim().toLowerCase();

    final projectsById = <String, Project>{
      for (final p in widget.availableProjects) p.id: p,
    };

    final recentProjects = widget.recentProjectIds
        .map((id) => projectsById[id])
        .whereType<Project>()
        .where((p) => p.id != currentId)
        .toList(growable: false);

    final filteredProjects = query.isEmpty
        ? widget.availableProjects
        : widget.availableProjects
              .where((p) => p.name.toLowerCase().contains(query))
              .toList(growable: false);

    Widget projectLeading(Project project, {required bool isSelected}) {
      final tokens = TasklyTokens.of(context);
      final value = project.primaryValue;
      final valueIcon = value == null
          ? null
          : (getIconDataFromName(value.iconName) ?? Icons.favorite_rounded);
      final valueColor = value == null
          ? null
          : ColorUtils.valueColorForTheme(context, value.color);
      final iconSize = tokens.spaceLg;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_rounded,
            size: iconSize,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          if (valueIcon != null) ...[
            SizedBox(width: tokens.spaceXs),
            Icon(
              valueIcon,
              size: iconSize,
              color: valueColor,
            ),
          ],
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
      child: PickerShell(
        title: l10n.selectProjectTitle,
        searchField: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.projectPickerSearchHint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                TasklyTokens.of(context).radiusMd,
              ),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) {
            _searchDebouncer.schedule(() {
              if (!mounted) return;
              setState(() {});
            });
          },
        ),
        child: ListView(
          children: [
            if (widget.allowNoProject)
              ListTile(
                leading: Icon(
                  Icons.inbox_outlined,
                  color: currentId.isEmpty
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.inboxLabel),
                trailing: currentId.isEmpty
                    ? Icon(Icons.check, color: colorScheme.primary)
                    : null,
                selected: currentId.isEmpty,
                onTap: () => Navigator.of(context).pop(
                  const ProjectPickerResultCleared(),
                ),
              ),
            if (recentProjects.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  TasklyTokens.of(context).spaceLg,
                  TasklyTokens.of(context).spaceMd,
                  TasklyTokens.of(context).spaceLg,
                  TasklyTokens.of(context).spaceXs,
                ),
                child: Text(
                  l10n.projectPickerRecentTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ...recentProjects.map((project) {
                final isSelected = project.id == currentId;
                final value = project.primaryValue;
                final subtitle = value == null
                    ? l10n.taskProjectValueNotSet
                    : l10n.taskProjectPickerValueSupport(value.name);
                return ListTile(
                  leading: projectLeading(project, isSelected: isSelected),
                  title: Text(project.name),
                  subtitle: Text(subtitle),
                  trailing: isSelected
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  selected: isSelected,
                  onTap: () => Navigator.of(context).pop(
                    ProjectPickerResultSelected(project),
                  ),
                );
              }),
              const Divider(height: 1),
            ],
            if (filteredProjects.isEmpty)
              Padding(
                padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
                child: Text(
                  l10n.projectPickerNoMatchingProjects,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...filteredProjects.map((project) {
                final isSelected = project.id == currentId;
                final value = project.primaryValue;
                final subtitle = value == null
                    ? l10n.taskProjectValueNotSet
                    : l10n.taskProjectPickerValueSupport(value.name);
                return ListTile(
                  leading: projectLeading(project, isSelected: isSelected),
                  title: Text(project.name),
                  subtitle: Text(subtitle),
                  trailing: isSelected
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  selected: isSelected,
                  onTap: () => Navigator.of(context).pop(
                    ProjectPickerResultSelected(project),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

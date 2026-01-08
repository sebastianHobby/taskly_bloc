import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section_ref.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/presentation/features/screens/view/screen_creator_page.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_icon_picker.dart';

/// Page for managing custom screen definitions.
///
/// Users can view, edit, delete, and create new screens from this page.
class ScreenManagementPage extends StatefulWidget {
  const ScreenManagementPage({
    required this.userId,
    super.key,
  });

  /// The current user's ID for creating screens.
  final String userId;

  @override
  State<ScreenManagementPage> createState() => _ScreenManagementPageState();
}

class _ScreenManagementPageState extends State<ScreenManagementPage> {
  late final ScreenDefinitionsRepositoryContract _screensRepository;

  @override
  void initState() {
    super.initState();
    _screensRepository = getIt<ScreenDefinitionsRepositoryContract>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Screens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'About Screens',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<ScreenDefinition>>(
        stream: _screensRepository.watchCustomScreens(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final customScreens = snapshot.data!;

          if (customScreens.isEmpty) {
            return const _EmptyView();
          }

          return _ScreenListView(
            screens: customScreens,
            onScreenTapped: (screen) => _navigateToCreator(
              context,
              existingScreen: screen,
            ),
            onDeleteTapped: (screen) => _confirmDelete(context, screen),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToListCreator(context),
        icon: const Icon(Icons.add),
        label: const Text('New Screen'),
      ),
    );
  }

  Future<void> _navigateToListCreator(
    BuildContext context, {
    ScreenDefinition? existingScreen,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ScreenCreatorPage(
          screensRepository: _screensRepository,
          userId: widget.userId,
          existingScreen: existingScreen,
        ),
      ),
    );

    if ((result ?? false) && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            existingScreen != null
                ? 'Screen updated successfully'
                : 'Screen created successfully',
          ),
        ),
      );
    }
  }

  Future<void> _navigateToCreator(
    BuildContext context, {
    ScreenDefinition? existingScreen,
  }) async {
    final isAllocationScreen =
        existingScreen?.sections.any(
          (s) => s.templateId == SectionTemplateId.allocation,
        ) ??
        false;

    if (isAllocationScreen && existingScreen != null) {
      Routing.toScreenKey(context, existingScreen.screenKey);
      return;
    }

    return _navigateToListCreator(context, existingScreen: existingScreen);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ScreenDefinition screen,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Screen'),
        content: Text(
          'Are you sure you want to delete "${screen.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _screensRepository.deleteCustomScreen(screen.screenKey);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${screen.name}"')),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Custom Screens'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom screens let you create personalized views for your tasks, '
                'projects, and labels.',
              ),
              SizedBox(height: 16),
              Text(
                'Each screen can:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Show specific types of items (tasks, projects, labels)'),
              Text('• Group items by project, label, priority, etc.'),
              Text('• Sort by various fields'),
              Text('• Filter completed or archived items'),
              SizedBox(height: 16),
              Text(
                'Custom screens appear in your navigation sidebar alongside '
                'the built-in screens.',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Empty View
// =============================================================================

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_customize,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Custom Screens',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap + to create custom screens and organize\n'
              'your tasks, projects, and labels your way.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Error View
// =============================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Screen List View
// =============================================================================

class _ScreenListView extends StatelessWidget {
  const _ScreenListView({
    required this.screens,
    required this.onScreenTapped,
    required this.onDeleteTapped,
  });

  final List<ScreenDefinition> screens;
  final void Function(ScreenDefinition) onScreenTapped;
  final void Function(ScreenDefinition) onDeleteTapped;

  @override
  Widget build(BuildContext context) {
    final sortedScreens = List<ScreenDefinition>.from(screens)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final screen in sortedScreens)
          _ScreenTile(
            screen: screen,
            onTap: () => onScreenTapped(screen),
            onDelete: () => onDeleteTapped(screen),
          ),
      ],
    );
  }
}

// =============================================================================
// Screen Tile
// =============================================================================

class _ScreenTile extends StatelessWidget {
  const _ScreenTile({
    required this.screen,
    required this.onTap,
    required this.onDelete,
  });

  final ScreenDefinition screen;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = FormBuilderIconPicker.getIconData(screen.chrome.iconName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon ?? Icons.view_list,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            screen.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Note: isActive is now stored in preferences, not definition
                      ],
                    ),
                    const SizedBox(height: 4),
                    _ScreenMetadata(screen: screen),
                  ],
                ),
              ),

              // Delete action
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Screen Metadata
// =============================================================================

class _ScreenMetadata extends StatelessWidget {
  const _ScreenMetadata({required this.screen});

  final ScreenDefinition screen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final sections = screen.sections;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.view_list,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(_getInferredScreenTypeLabel(sections), style: textStyle),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(_getEntityTypeFromSections(sections), style: textStyle),
          ],
        ),
      ],
    );
  }

  /// Infers a display label for the screen type from sections.
  String _getInferredScreenTypeLabel(List<SectionRef> sections) {
    if (sections.any((s) => s.templateId == SectionTemplateId.allocation)) {
      return 'Focus';
    }
    if (sections.any((s) => s.templateId == SectionTemplateId.agenda)) {
      return 'Agenda';
    }
    return 'List';
  }

  String _getEntityTypeFromSections(List<SectionRef> sections) {
    for (final section in sections) {
      switch (section.templateId) {
        case SectionTemplateId.taskList:
        case SectionTemplateId.allocation:
        case SectionTemplateId.agenda:
          return 'Tasks';
        case SectionTemplateId.projectList:
          return 'Projects';
        case SectionTemplateId.valueList:
          return 'Values';
      }
    }
    return 'Items';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskly_domain/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_tile_capabilities.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/widgets/entity_header.dart';

class EntityHeaderSectionRenderer extends StatelessWidget {
  const EntityHeaderSectionRenderer({
    required this.data,
    super.key,
    this.onTap,
  });

  final SectionDataResult data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return switch (data) {
      EntityHeaderProjectSectionResult(
        :final project,
        :final showCheckbox,
        :final showMetadata,
      ) =>
        EntityHeader.project(
          project: project,
          showCheckbox: showCheckbox,
          showMetadata: showMetadata,
          onTap: onTap,
          onCheckboxChanged: showCheckbox
              ? (value) {
                  context.read<TileIntentDispatcher>().dispatch(
                    context,
                    TileIntentSetCompletion(
                      entityType: EntityType.project,
                      entityId: project.id,
                      completed: value ?? false,
                      scope: CompletionScope.entity,
                    ),
                  );
                }
              : null,
        ),
      EntityHeaderValueSectionResult(
        :final value,
        :final taskCount,
        :final showMetadata,
      ) =>
        EntityHeader.value(
          value: value,
          taskCount: taskCount,
          showMetadata: showMetadata,
          onTap: onTap,
        ),
      EntityHeaderMissingSectionResult(:final entityType) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Missing $entityType'),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

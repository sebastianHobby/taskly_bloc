import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';

/// Resolves the effective [EntityStyleV1] for a given template + module type.
///
/// Resolution precedence:
/// 1) explicit [override]
/// 2) (template, sectionTemplateId) default
/// 3) global default
final class EntityStyleResolver {
  const EntityStyleResolver();

  EntityStyleV1 resolve({
    required ScreenTemplateSpec template,
    required String sectionTemplateId,
    EntityStyleOverrideV1? override,
  }) {
    final base = _defaultFor(
      template: template,
      sectionTemplateId: sectionTemplateId,
    );
    if (override == null) return base;

    return base.copyWith(
      density: override.density ?? base.density,
      taskVariant: override.taskVariant ?? base.taskVariant,
      projectVariant: override.projectVariant ?? base.projectVariant,
      valueVariant: override.valueVariant ?? base.valueVariant,
      showAgendaTagPills:
          override.showAgendaTagPills ?? base.showAgendaTagPills,
    );
  }

  EntityStyleV1 _defaultFor({
    required ScreenTemplateSpec template,
    required String sectionTemplateId,
  }) {
    // Currently, USM screens relevant to entity tiles use standardScaffoldV1.
    // Keep defaults primarily keyed off module type.

    if (sectionTemplateId == SectionTemplateId.agendaV2) {
      return const EntityStyleV1(
        density: EntityDensityV1.comfortable,
        taskVariant: TaskTileVariant.agenda,
        projectVariant: ProjectTileVariant.agenda,
        showAgendaTagPills: true,
      );
    }

    // List-like entity sections.
    if (sectionTemplateId == SectionTemplateId.taskListV2 ||
        sectionTemplateId == SectionTemplateId.interleavedListV2 ||
        sectionTemplateId == SectionTemplateId.hierarchyValueProjectTaskV2 ||
        sectionTemplateId == SectionTemplateId.myDayRankedTasksV1) {
      return const EntityStyleV1(
        density: EntityDensityV1.comfortable,
        taskVariant: TaskTileVariant.listTile,
        projectVariant: ProjectTileVariant.listTile,
        showAgendaTagPills: false,
      );
    }

    // Default fallback.
    return const EntityStyleV1();
  }
}

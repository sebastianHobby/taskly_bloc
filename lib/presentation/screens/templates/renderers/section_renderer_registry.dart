import 'package:flutter/material.dart';
import 'package:taskly_domain/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/agenda_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_banner_section_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_inbox_section_renderer_v1.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/create_value_cta_section_renderer_v1.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/entity_header_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/hierarchy_value_project_task_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/journal_history_list_section_renderer_v1.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/journal_history_teaser_section_renderer_v1.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/journal_manage_trackers_section_renderer_v1.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/journal_today_composer_section_renderer_v1.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/journal_today_entries_section_renderer_v1.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/my_day_hero_v1_section.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/my_day_ranked_tasks_v1_section.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/task_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/value_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

/// Registry that renders a [SectionVm] into a sliver widget.
///
/// This centralizes the template-id/type switching so [SectionWidget] can stay
/// small and stable.
abstract interface class SectionRendererRegistry {
  /// Builds the sliver for a resolved section.
  Widget buildSection({
    required BuildContext context,
    required SectionVm section,
    required String? persistenceKey,
    required DisplayConfig? displayConfig,
    required FocusMode? focusMode,
    required void Function(dynamic entity)? onEntityTap,
    required VoidCallback? onEntityHeaderTap,
  });
}

/// Default renderer registry for the typed unified screen pipeline.
final class DefaultSectionRendererRegistry implements SectionRendererRegistry {
  const DefaultSectionRendererRegistry();

  @override
  Widget buildSection({
    required BuildContext context,
    required SectionVm section,
    required String? persistenceKey,
    required DisplayConfig? displayConfig,
    required FocusMode? focusMode,
    required void Function(dynamic entity)? onEntityTap,
    required VoidCallback? onEntityHeaderTap,
  }) {
    if (section.templateId == SectionTemplateId.statisticsDashboard) {
      return const SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Text('Statistics dashboard not implemented yet.'),
        ),
      );
    }

    if (section.isLoading) {
      return const SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (section.error case final error?) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        sliver: SliverToBoxAdapter(child: Text('Section error: $error')),
      );
    }

    final result = section.data;

    final sliver = section.map(
      taskListV2: (s) {
        if (result case final DataV2SectionResult d) {
          return TaskListRendererV2(
            data: d,
            params: s.params,
            entityStyle: s.entityStyle,
            title: s.title,
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      valueListV2: (s) {
        if (result case final DataV2SectionResult d) {
          return ValueListRendererV2(
            data: d,
            params: s.params,
            entityStyle: s.entityStyle,
            title: s.title,
            persistenceKey: persistenceKey,
            enableSegmentedTabs: false,
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      interleavedListV2: (s) {
        if (result case final DataV2SectionResult d) {
          return InterleavedListRendererV2(
            items: d.items,
            enrichment: d.enrichment,
            params: s.params,
            entityStyle: s.entityStyle,
            title: s.title,
            persistenceKey: persistenceKey,
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      hierarchyValueProjectTaskV2: (s) {
        if (result case final HierarchyValueProjectTaskV2SectionResult d) {
          return HierarchyValueProjectTaskRendererV2(
            data: d,
            params: s.params,
            entityStyle: s.entityStyle,
            title: s.title,
            persistenceKey: persistenceKey,
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      agendaV2: (s) {
        if (result case final AgendaSectionResult d) {
          return SliverFillRemaining(
            hasScrollBody: true,
            child: AgendaSectionRenderer(
              params: s.params,
              data: d,
              entityStyle: s.entityStyle,
              onTaskTap: (task) => onEntityTap?.call(task),
            ),
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      attentionBannerV2: (s) {
        if (result case final AttentionBannerV2SectionResult d) {
          return SliverToBoxAdapter(
            child: AttentionBannerSectionRendererV2(
              data: d,
              title: s.title,
            ),
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      attentionInboxV1: (s) {
        return SliverFillRemaining(
          hasScrollBody: true,
          child: AttentionInboxSectionRendererV1(
            params: s.params,
          ),
        );
      },
      entityHeader: (s) {
        if (result is EntityHeaderProjectSectionResult ||
            result is EntityHeaderValueSectionResult ||
            result is EntityHeaderMissingSectionResult) {
          return SliverToBoxAdapter(
            child: EntityHeaderSectionRenderer(
              data: result!,
              onTap: onEntityHeaderTap,
            ),
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      myDayRankedTasksV1: (s) {
        if (result case final HierarchyValueProjectTaskV2SectionResult d) {
          return MyDayRankedTasksV1Section(
            data: d.items,
            title: s.title,
            enrichment: d.enrichment,
            entityStyle: s.entityStyle,
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      myDayHeroV1: (s) {
        if (result case final MyDayHeroV1SectionResult d) {
          return SliverToBoxAdapter(child: MyDayHeroV1Section(data: d));
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      createValueCtaV1: (s) {
        return SliverToBoxAdapter(
          child: CreateValueCtaSectionRendererV1(
            title: s.title ?? 'Create New Value',
          ),
        );
      },
      journalTodayComposerV1: (s) {
        if (result case final JournalTodayComposerV1SectionResult d) {
          return SliverToBoxAdapter(
            child: JournalTodayComposerSectionRendererV1(
              pinnedTrackers: d.pinnedTrackers,
              onAddLog: () {
                Routing.toJournalEntryNew(context);
              },
              onQuickAddTracker: (trackerId) {
                Routing.toJournalEntryNew(
                  context,
                  preselectedTrackerIds: {trackerId},
                );
              },
            ),
          );
        }
        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      journalTodayEntriesV1: (s) {
        if (result case final JournalTodayEntriesV1SectionResult d) {
          return SliverToBoxAdapter(
            child: JournalTodayEntriesSectionRendererV1(
              entries: d.entries,
              eventsByEntryId: d.eventsByEntryId,
              definitionById: d.definitionById,
              moodTrackerId: d.moodTrackerId,
              onEntryTap: (entry) {
                Routing.toJournalEntryEdit(context, entry.id);
              },
            ),
          );
        }
        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      journalHistoryTeaserV1: (s) {
        return SliverToBoxAdapter(
          child: JournalHistoryTeaserSectionRendererV1(
            onOpenHistory: () {
              Routing.pushScreenKey(context, 'journal_history');
            },
          ),
        );
      },
      journalHistoryListV1: (s) {
        if (result case final JournalHistoryListV1SectionResult d) {
          return SliverToBoxAdapter(
            child: JournalHistoryListSectionRendererV1(
              entries: d.entries,
              onEntryTap: (entry) {
                Routing.toJournalEntryEdit(context, entry.id);
              },
            ),
          );
        }
        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      journalManageTrackersV1: (s) {
        if (result case final JournalManageTrackersV1SectionResult d) {
          return SliverToBoxAdapter(
            child: JournalManageTrackersSectionRendererV1(
              definitions: d.visibleDefinitions,
              preferenceByTrackerId: d.preferenceByTrackerId,
            ),
          );
        }
        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      unknown: (_) => SliverToBoxAdapter(child: _buildUnknownSection(section)),
    );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      sliver: sliver,
    );
  }

  Widget _buildUnknownSection(SectionVm section) {
    return Text('Unsupported section data: ${section.templateId}');
  }
}

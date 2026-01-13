import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_params_codec.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/issues_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_tile_variants.dart';

void main() {
  group('SectionTemplateParamsCodec', () {
    test('decodes known templates into typed params', () {
      final codec = SectionTemplateParamsCodec();

      final allocation = codec.decode(SectionTemplateId.allocation, {
        'task_tile_variant': 'list_tile',
      });
      expect(allocation, isA<AllocationSectionParams>());

      final issues = codec.decode(SectionTemplateId.issuesSummary, {
        'attention_item_tile_variant': 'standard',
      });
      expect(issues, isA<IssuesSummarySectionParams>());

      final entityHeader = codec.decode(SectionTemplateId.entityHeader, {
        'entity_type': 'project',
        'entity_id': 'p1',
      });
      expect(entityHeader, isA<EntityHeaderSectionParams>());
    });

    test('throws when required fields are missing (strict decode)', () {
      final codec = SectionTemplateParamsCodec();

      expect(
        () => codec.decode(SectionTemplateId.allocation, const {}),
        throwsA(anything),
      );

      expect(
        () => codec.decode(SectionTemplateId.issuesSummary, const {}),
        throwsA(anything),
      );

      expect(
        () => codec.decode(SectionTemplateId.entityHeader, const {}),
        throwsA(anything),
      );
    });

    test('encode round-trips for known params types', () {
      final codec = SectionTemplateParamsCodec();

      const allocation = AllocationSectionParams(
        taskTileVariant: TaskTileVariant.listTile,
      );
      expect(
        codec.decode(
          SectionTemplateId.allocation,
          codec.encode(
            SectionTemplateId.allocation,
            allocation,
          ),
        ),
        isA<AllocationSectionParams>(),
      );

      const issues = IssuesSummarySectionParams(
        attentionItemTileVariant: AttentionItemTileVariant.standard,
      );
      expect(
        codec.decode(
          SectionTemplateId.issuesSummary,
          codec.encode(
            SectionTemplateId.issuesSummary,
            issues,
          ),
        ),
        isA<IssuesSummarySectionParams>(),
      );

      const entityHeader = EntityHeaderSectionParams(
        entityType: 'project',
        entityId: 'p1',
      );
      expect(
        codec.decode(
          SectionTemplateId.entityHeader,
          codec.encode(
            SectionTemplateId.entityHeader,
            entityHeader,
          ),
        ),
        isA<EntityHeaderSectionParams>(),
      );
    });
  });
}

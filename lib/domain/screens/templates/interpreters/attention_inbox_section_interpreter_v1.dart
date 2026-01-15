import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_inbox_section_params_v1.dart';

/// Interpreter for the Attention Inbox section.
///
/// The inbox section is interactive and owns its own BLoC in presentation.
/// This interpreter exists to participate in the typed USM module pipeline.
class AttentionInboxSectionInterpreterV1
    implements SectionTemplateInterpreter<AttentionInboxSectionParamsV1> {
  @override
  String get templateId => SectionTemplateId.attentionInboxV1;

  @override
  Stream<Object?> watch(AttentionInboxSectionParamsV1 params) {
    return Stream<Object?>.value(null);
  }

  @override
  Future<Object?> fetch(AttentionInboxSectionParamsV1 params) async {
    return null;
  }
}

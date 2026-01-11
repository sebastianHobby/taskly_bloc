import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';

class SectionTemplateInterpreterRegistry {
  SectionTemplateInterpreterRegistry(
    Iterable<SectionTemplateInterpreter<dynamic>> interpreters,
  ) : _byId = {
        for (final interpreter in interpreters)
          interpreter.templateId: interpreter,
      };

  final Map<String, SectionTemplateInterpreter<dynamic>> _byId;

  SectionTemplateInterpreter<dynamic> get(String templateId) {
    final interpreter = _byId[templateId];
    if (interpreter == null) {
      throw StateError(
        'No section template interpreter registered for $templateId',
      );
    }
    return interpreter;
  }
}

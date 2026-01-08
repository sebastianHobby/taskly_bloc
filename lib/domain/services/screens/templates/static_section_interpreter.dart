import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_params_codec.dart';

/// Interpreter for templates that don't require any data.
class StaticSectionInterpreter
    implements SectionTemplateInterpreter<EmptySectionParams> {
  StaticSectionInterpreter({required this.templateId});

  @override
  final String templateId;

  @override
  Stream<Object?> watch(EmptySectionParams params) => Stream.value(null);

  @override
  Future<Object?> fetch(EmptySectionParams params) async => null;
}

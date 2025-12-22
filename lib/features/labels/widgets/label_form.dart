import 'package:flutter/material.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/domain/domain.dart';

class LabelForm extends StatelessWidget {
  const LabelForm({
    required this.formKey,
    required this.initialData,
    required this.onSubmit,
    required this.submitTooltip,
    this.initialType,
    this.lockType = false,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Label? initialData;
  final LabelType? initialType;
  final bool lockType;

  static const _defaultColorHex = '#000000';

  static Color _colorFromHex(String hex) {
    final normalized = hex.replaceAll('#', '');
    if (normalized.length != 6) return const Color(0xFF000000);
    return Color(int.parse('FF$normalized', radix: 16));
  }

  static String _toHex(Color color) {
    final rgb = color.value & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> initialValues = {
      'name': initialData?.name.trim() ?? '',
      'colour': _colorFromHex(initialData?.color ?? _defaultColorHex),
      'type': initialData?.type ?? initialType ?? LabelType.label,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FormBuilder(
              key: formKey,
              initialValue: initialValues,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderTextField(
                      name: 'name',
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Name',
                        border: InputBorder.none,
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Name is required',
                        ),
                        FormBuilderValidators.minLength(
                          1,
                          errorText: 'Name must not be empty',
                        ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderColorPickerField(
                      name: 'colour',
                      colorPickerType: ColorPickerType.blockPicker,
                      availableColors: const [
                        Colors.red,
                        Colors.pink,
                        Colors.purple,
                        Colors.deepPurple,
                        Colors.indigo,
                        Colors.blue,
                        Colors.lightBlue,
                        Colors.cyan,
                        Colors.teal,
                        Colors.green,
                        Colors.lightGreen,
                        Colors.lime,
                        Colors.yellow,
                        Colors.amber,
                        Colors.orange,
                        Colors.deepOrange,
                        Colors.brown,
                        Colors.grey,
                        Colors.blueGrey,
                        Colors.black,
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Colour',
                        border: InputBorder.none,
                      ),
                      valueTransformer: (colour) {
                        if (colour == null) return _defaultColorHex;
                        return _toHex(colour);
                      },
                      validator: FormBuilderValidators.required(
                        errorText: 'Colour is required',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: lockType
                        ? const SizedBox.shrink()
                        : FormBuilderDropdown<LabelType>(
                            name: 'type',
                            decoration: const InputDecoration(
                              hintText: 'Type',
                              border: InputBorder.none,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: LabelType.label,
                                child: Text('Label'),
                              ),
                              DropdownMenuItem(
                                value: LabelType.value,
                                child: Text('Value'),
                              ),
                            ],
                            validator: FormBuilderValidators.required(
                              errorText: 'Type is required',
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton.filled(
                  icon: const Icon(Icons.check),
                  tooltip: submitTooltip,
                  onPressed: onSubmit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// A modern emoji picker field displayed as a chip.
///
/// Features:
/// - Material 3 chip design
/// - Full emoji keyboard with categories
/// - Visual emoji display in chip
/// - Search functionality
class FormBuilderEmojiPickerModern extends StatelessWidget {
  const FormBuilderEmojiPickerModern({
    required this.name,
    this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.enabled = true,
    this.isRequired = false,
    this.showLabel = true,
    this.compact = false,
    super.key,
  });

  final String name;
  final String? label;
  final String? hint;
  final String? initialValue;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool isRequired;

  /// Whether to show the label above the chip.
  final bool showLabel;

  /// If true, removes padding for inline use.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FormBuilderField<String>(
        name: name,
        initialValue: initialValue,
        validator: validator,
        enabled: enabled,
        builder: (FormFieldState<String> field) {
          final hasEmoji = field.value != null && field.value!.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLabel && label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    label!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ActionChip(
                avatar: hasEmoji
                    ? Text(
                        field.value!,
                        style: const TextStyle(fontSize: 18),
                      )
                    : Icon(
                        Icons.emoji_emotions_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                label: Text(hasEmoji ? 'Emoji' : 'Emoji'),
                onPressed: enabled
                    ? () => _showEmojiPickerDialog(context, field)
                    : null,
                backgroundColor: colorScheme.surfaceContainerLow,
                side: BorderSide(
                  color: field.hasError
                      ? colorScheme.error
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    field.errorText ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEmojiPickerDialog(
    BuildContext context,
    FormFieldState<String> field,
  ) async {
    final selectedEmoji = await showDialog<String>(
      context: context,
      builder: (context) => _EmojiPickerDialog(
        currentEmoji: field.value,
      ),
    );

    if (selectedEmoji != null) {
      field.didChange(selectedEmoji);
    }
  }
}

class _EmojiPickerDialog extends StatefulWidget {
  const _EmojiPickerDialog({
    this.currentEmoji,
  });

  final String? currentEmoji;

  @override
  State<_EmojiPickerDialog> createState() => _EmojiPickerDialogState();
}

class _EmojiPickerDialogState extends State<_EmojiPickerDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Emoji',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.currentEmoji != null &&
                      widget.currentEmoji!.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(''),
                      child: Text(
                        'Clear',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  Navigator.of(context).pop(emoji.emoji);
                },
                config: Config(
                  height: 400,
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: colorScheme.surface,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor: colorScheme.surface,
                    iconColorSelected: colorScheme.primary,
                    iconColor: colorScheme.onSurfaceVariant,
                    dividerColor: colorScheme.outlineVariant,
                    indicatorColor: colorScheme.primary,
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(
                    backgroundColor: colorScheme.surface,
                    buttonColor: colorScheme.surfaceContainerLow,
                    buttonIconColor: colorScheme.onSurfaceVariant,
                  ),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor: colorScheme.surface,
                    buttonIconColor: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

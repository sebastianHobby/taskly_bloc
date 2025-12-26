import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// A modern text field with consistent styling and Material 3 design.
///
/// Features:
/// - Consistent visual design across the app
/// - Proper Material 3 styling
/// - Built-in spacing and padding
/// - Support for different field types (title, description, etc.)
class FormBuilderTextFieldModern extends StatelessWidget {
  const FormBuilderTextFieldModern({
    required this.name,
    this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.isRequired = false,
    this.fieldType = ModernFieldType.standard,
    super.key,
  });

  final String name;
  final String? label;
  final String? hint;
  final String? initialValue;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isRequired;
  final ModernFieldType fieldType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(),
        vertical: _getVerticalPadding(),
      ),
      child: FormBuilderTextField(
        name: name,
        initialValue: initialValue,
        validator: validator,
        enabled: enabled,
        readOnly: readOnly,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        style: _getTextStyle(theme),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: _getFillColor(colorScheme),
          border: _getBorder(colorScheme),
          enabledBorder: _getBorder(colorScheme),
          focusedBorder: _getFocusedBorder(colorScheme),
          errorBorder: _getErrorBorder(colorScheme),
          focusedErrorBorder: _getErrorBorder(colorScheme),
          contentPadding: _getContentPadding(),
          counterText: maxLength != null ? '' : null,
          floatingLabelBehavior: fieldType == ModernFieldType.title
              ? FloatingLabelBehavior.never
              : FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  double _getHorizontalPadding() {
    return switch (fieldType) {
      ModernFieldType.title => 24.0,
      ModernFieldType.description => 24.0,
      ModernFieldType.standard => 16.0,
    };
  }

  double _getVerticalPadding() {
    return switch (fieldType) {
      ModernFieldType.title => 8.0,
      ModernFieldType.description => 12.0,
      ModernFieldType.standard => 8.0,
    };
  }

  TextStyle? _getTextStyle(ThemeData theme) {
    return switch (fieldType) {
      ModernFieldType.title => theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      ModernFieldType.description => theme.textTheme.bodyLarge,
      ModernFieldType.standard => theme.textTheme.bodyMedium,
    };
  }

  Color _getFillColor(ColorScheme colorScheme) {
    return switch (fieldType) {
      ModernFieldType.title => Colors.transparent,
      ModernFieldType.description => colorScheme.surfaceContainerLow,
      ModernFieldType.standard => colorScheme.surfaceContainerLow,
    };
  }

  OutlineInputBorder _getBorder(ColorScheme colorScheme) {
    return switch (fieldType) {
      ModernFieldType.title => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      ModernFieldType.description => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      ModernFieldType.standard => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    };
  }

  OutlineInputBorder _getFocusedBorder(ColorScheme colorScheme) {
    return switch (fieldType) {
      ModernFieldType.title => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      ModernFieldType.description => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      ModernFieldType.standard => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
    };
  }

  OutlineInputBorder _getErrorBorder(ColorScheme colorScheme) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        fieldType == ModernFieldType.description ? 16 : 12,
      ),
      borderSide: BorderSide(
        color: colorScheme.error,
        width: 2,
      ),
    );
  }

  EdgeInsetsGeometry _getContentPadding() {
    return switch (fieldType) {
      ModernFieldType.title => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      ModernFieldType.description => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      ModernFieldType.standard => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    };
  }
}

/// Different visual styles for modern text fields.
enum ModernFieldType {
  /// Large title field with prominent styling
  title,

  /// Multi-line description field
  description,

  /// Standard single-line field
  standard,
}

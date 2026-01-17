import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/domain/core/model/entity_operation.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';

void showEditorErrorSnackBar(BuildContext context, Object error) {
  final message = friendlyErrorMessageForUi(error, context.l10n);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void showEditorSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> handleEditorOperationSuccess(
  BuildContext context, {
  required EntityOperation operation,
  required String createdMessage,
  required String updatedMessage,
  required String deletedMessage,
  VoidCallback? onSaved,
}) async {
  final message = switch (operation) {
    EntityOperation.create => createdMessage,
    EntityOperation.update => updatedMessage,
    EntityOperation.delete => deletedMessage,
  };

  showEditorSuccessSnackBar(context, message);
  onSaved?.call();
  await closeEditor(context);
}

Future<void> closeEditor(BuildContext context) {
  return Navigator.of(context).maybePop();
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/mixins/form_submission_mixin.dart';
import 'package:taskly_bloc/core/shared/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/features/labels/bloc/label_detail_bloc.dart';
import 'package:taskly_bloc/features/labels/widgets/label_form.dart';

class LabelDetailSheetPage extends StatelessWidget {
  const LabelDetailSheetPage({
    required this.labelRepository,
    this.labelId,
    this.initialType,
    this.lockType = false,
    this.onSaved,
    super.key,
  });

  final LabelRepositoryContract labelRepository;
  final String? labelId;
  final LabelType? initialType;
  final bool lockType;

  /// Optional callback when a label is saved (created or updated).
  /// Called with the label ID after successful save.
  final void Function(String labelId)? onSaved;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LabelDetailBloc(
        labelRepository: labelRepository,
        labelId: labelId,
      ),
      lazy: false,
      child: LabelDetailSheetView(
        labelId: labelId,
        initialType: initialType,
        lockType: lockType,
        onSaved: onSaved,
      ),
    );
  }
}

class LabelDetailSheetView extends StatefulWidget {
  const LabelDetailSheetView({
    this.labelId,
    this.initialType,
    this.lockType = false,
    this.onSaved,
    super.key,
  });

  final String? labelId;
  final LabelType? initialType;
  final bool lockType;

  /// Optional callback when a label is saved.
  final void Function(String labelId)? onSaved;

  @override
  State<LabelDetailSheetView> createState() => _LabelDetailSheetViewState();
}

class _LabelDetailSheetViewState extends State<LabelDetailSheetView>
    with FormSubmissionMixin {
  GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  String? _formLabelId;

  void _ensureFreshFormKeyFor(String? labelId) {
    if (_formLabelId == labelId) return;
    _formLabelId = labelId;
    _formKey = GlobalKey<FormBuilderState>();
  }

  void _onSubmit(String? id, {LabelType? existingType}) {
    final formValues = validateAndGetFormValues(_formKey);
    if (formValues == null) return;

    final name = extractStringValue(formValues, 'name');
    final color = extractStringValue(formValues, 'colour');
    final type = widget.lockType
        ? (widget.initialType ?? existingType ?? LabelType.label)
        : (formValues['type'] as LabelType);
    final iconName = extractStringValue(formValues, 'iconName').isEmpty
        ? null
        : extractStringValue(formValues, 'iconName');

    if (id == null) {
      context.read<LabelDetailBloc>().add(
        LabelDetailEvent.create(
          name: name,
          color: color,
          type: type,
          iconName: iconName,
        ),
      );
    } else {
      context.read<LabelDetailBloc>().add(
        LabelDetailEvent.update(
          id: id,
          name: name,
          color: color,
          type: type,
          iconName: iconName,
        ),
      );
    }
  }

  String _successMessageFor(EntityOperation operation, AppLocalizations l10n) {
    final isValueFlow =
        widget.lockType && widget.initialType == LabelType.value;
    if (!isValueFlow) {
      return switch (operation) {
        EntityOperation.create => l10n.labelCreatedSuccessfully,
        EntityOperation.update => l10n.labelUpdatedSuccessfully,
        EntityOperation.delete => l10n.labelDeletedSuccessfully,
      };
    }

    return switch (operation) {
      EntityOperation.create => l10n.valueCreatedSuccessfully,
      EntityOperation.update => l10n.valueUpdatedSuccessfully,
      EntityOperation.delete => l10n.valueDeletedSuccessfully,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LabelDetailBloc, LabelDetailState>(
      listenWhen: (previous, current) {
        return current is LabelDetailOperationSuccess ||
            current is LabelDetailOperationFailure;
      },
      listener: (context, state) {
        switch (state) {
          case LabelDetailOperationSuccess(:final operation):
            final message = _successMessageFor(operation, context.l10n);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            // Call onSaved callback if provided (for edit scenarios that need refresh)
            if (widget.labelId != null) {
              widget.onSaved?.call(widget.labelId!);
            }
            unawaited(Navigator.of(context).maybePop());
          case LabelDetailOperationFailure(:final errorDetails):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  friendlyErrorMessageForUi(errorDetails.error, context.l10n),
                ),
              ),
            );
          default:
            return;
        }
      },
      buildWhen: (previous, current) {
        return current is LabelDetailInitial ||
            current is LabelDetailLoadInProgress ||
            current is LabelDetailLoadSuccess;
      },
      builder: (context, state) {
        switch (state) {
          case LabelDetailInitial():
            _ensureFreshFormKeyFor(null);
            return LabelForm(
              initialData: null,
              initialType: widget.initialType,
              lockType: widget.lockType,
              formKey: _formKey,
              onSubmit: () => _onSubmit(null),
              submitTooltip: context.l10n.actionCreate,
              onClose: () => Navigator.of(context).maybePop(),
            );
          case LabelDetailLoadInProgress():
            return const Center(child: CircularProgressIndicator());
          case LabelDetailLoadSuccess(:final label):
            _ensureFreshFormKeyFor(label.id);
            return LabelForm(
              initialData: label,
              initialType: widget.initialType,
              lockType: widget.lockType,
              formKey: _formKey,
              onSubmit: () => _onSubmit(label.id, existingType: label.type),
              onDelete: () async {
                final confirmed = await showDeleteConfirmationDialog(
                  context: context,
                  title:
                      'Delete ${label.type == LabelType.label ? 'Label' : 'Value'}',
                  itemName: label.name,
                  description:
                      'This ${label.type == LabelType.label ? 'label' : 'value'} will be removed from all tasks. This action cannot be undone.',
                );
                if (confirmed && context.mounted) {
                  context.read<LabelDetailBloc>().add(
                    LabelDetailEvent.delete(id: label.id),
                  );
                }
              },
              submitTooltip: context.l10n.actionUpdate,
              onClose: () => Navigator.of(context).maybePop(),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_feedback.dart';
import 'package:taskly_bloc/presentation/shared/mixins/form_submission_mixin.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/value_form.dart';

class ValueDetailSheetPage extends StatelessWidget {
  const ValueDetailSheetPage({
    required this.valueRepository,
    this.valueId,
    this.onSaved,
    super.key,
  });

  final ValueRepositoryContract valueRepository;
  final String? valueId;

  /// Optional callback when a value is saved (created or updated).
  /// Called with the value ID after successful save.
  final void Function(String valueId)? onSaved;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ValueDetailBloc(
        valueRepository: valueRepository,
        valueId: valueId,
      ),
      lazy: false,
      child: ValueDetailSheetView(
        valueId: valueId,
        onSaved: onSaved,
      ),
    );
  }
}

class ValueDetailSheetView extends StatefulWidget {
  const ValueDetailSheetView({
    this.valueId,
    this.onSaved,
    super.key,
  });

  final String? valueId;

  /// Optional callback when a value is saved.
  final void Function(String valueId)? onSaved;

  @override
  State<ValueDetailSheetView> createState() => _ValueDetailSheetViewState();
}

class _ValueDetailSheetViewState extends State<ValueDetailSheetView>
    with FormSubmissionMixin {
  GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  String? _formValueId;
  ValueDraft _draft = ValueDraft.empty();

  void _ensureFreshFormKeyFor(String? valueId) {
    if (_formValueId == valueId) return;
    _formValueId = valueId;
    _formKey = GlobalKey<FormBuilderState>();
  }

  void _syncDraftFromFormValues(Map<String, dynamic> formValues) {
    final name = extractStringValue(formValues, ValueFieldKeys.name.id);
    final rawIconName = extractStringValue(
      formValues,
      ValueFieldKeys.iconName.id,
    );
    final iconName = rawIconName.trim().isEmpty ? null : rawIconName.trim();
    final colorValue = formValues[ValueFieldKeys.colour.id] as Color?;
    final color = colorValue != null
        ? ColorUtils.toHexWithHash(colorValue)
        : _draft.color;

    final priority =
        (formValues[ValueFieldKeys.priority.id] as ValuePriority?) ??
        _draft.priority;

    _draft = _draft.copyWith(
      name: name,
      color: color,
      priority: priority,
      iconName: iconName,
    );
  }

  void _onSubmit(String? id) {
    final formValues = validateAndGetFormValues(_formKey);
    if (formValues == null) return;

    _syncDraftFromFormValues(formValues);

    final bloc = context.read<ValueDetailBloc>();
    if (id == null) {
      bloc.add(
        ValueDetailEvent.create(
          command: CreateValueCommand(
            name: _draft.name,
            color: _draft.color,
            priority: _draft.priority,
            iconName: _draft.iconName,
          ),
        ),
      );
    } else {
      bloc.add(
        ValueDetailEvent.update(
          command: UpdateValueCommand(
            id: id,
            name: _draft.name,
            color: _draft.color,
            priority: _draft.priority,
            iconName: _draft.iconName,
          ),
        ),
      );
    }
  }

  Future<void> _onDelete({
    required String id,
    required String itemName,
  }) async {
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      title: context.l10n.deleteValue,
      itemName: itemName,
      description: context.l10n.deleteValueCascadeDescription,
    );

    if (confirmed && mounted) {
      context.read<ValueDetailBloc>().add(ValueDetailEvent.delete(id: id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ValueDetailBloc, ValueDetailState>(
      listenWhen: (previous, current) =>
          current is ValueDetailOperationSuccess ||
          current is ValueDetailValidationFailure ||
          current is ValueDetailOperationFailure,
      listener: (context, state) {
        state.mapOrNull(
          operationSuccess: (success) {
            unawaited(
              handleEditorOperationSuccess(
                context,
                operation: success.operation,
                createdMessage: context.l10n.valueCreatedSuccessfully,
                updatedMessage: context.l10n.valueUpdatedSuccessfully,
                deletedMessage: context.l10n.valueDeletedSuccessfully,
                onSaved: widget.valueId != null
                    ? () => widget.onSaved?.call(widget.valueId!)
                    : null,
              ),
            );
          },
          validationFailure: (failure) {
            applyValidationFailureToForm(_formKey, failure.failure, context);
          },
          operationFailure: (failure) {
            showEditorErrorSnackBar(context, failure.errorDetails.error);
          },
        );
      },
      buildWhen: (previous, current) =>
          current is ValueDetailInitial ||
          current is ValueDetailLoadInProgress ||
          current is ValueDetailLoadSuccess,
      builder: (context, state) {
        return state.maybeMap(
          loadSuccess: (success) {
            _ensureFreshFormKeyFor(success.value.id);
            _draft = ValueDraft.fromValue(success.value);
            return ValueForm(
              formKey: _formKey,
              initialData: success.value,
              onChanged: _syncDraftFromFormValues,
              onSubmit: () => _onSubmit(success.value.id),
              onDelete: () => _onDelete(
                id: success.value.id,
                itemName: success.value.name,
              ),
              submitTooltip: context.l10n.actionUpdate,
              onClose: () => unawaited(closeEditor(context)),
            );
          },
          loadInProgress: (_) =>
              const Center(child: CircularProgressIndicator()),
          orElse: () {
            // Initial state or error state where we can still show the form for creation
            if (widget.valueId == null) {
              _ensureFreshFormKeyFor(null);
              _draft = ValueDraft.empty();
              return ValueForm(
                formKey: _formKey,
                initialData: null,
                onChanged: _syncDraftFromFormValues,
                onSubmit: () => _onSubmit(null),
                submitTooltip: context.l10n.actionCreate,
                onClose: () => unawaited(closeEditor(context)),
              );
            }
            return const Center(child: Text('Something went wrong'));
          },
        );
      },
    );
  }
}

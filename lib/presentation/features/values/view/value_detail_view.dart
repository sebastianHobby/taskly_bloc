import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/presentation/shared/mixins/form_submission_mixin.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/domain/core/model/entity_operation.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
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

  void _ensureFreshFormKeyFor(String? valueId) {
    if (_formValueId == valueId) return;
    _formValueId = valueId;
    _formKey = GlobalKey<FormBuilderState>();
  }

  void _onSubmit(String? id) {
    final formValues = validateAndGetFormValues(_formKey);
    if (formValues == null) return;

    final name = extractStringValue(formValues, 'name');
    // Color is stored as a Color object, convert to hex string
    final colorValue = formValues['colour'] as Color?;
    final color = colorValue != null
        ? ColorUtils.toHexWithHash(colorValue)
        : '#000000';
    final priority = formValues['priority'] as ValuePriority;
    final iconName = extractStringValue(formValues, 'iconName').isEmpty
        ? null
        : extractStringValue(formValues, 'iconName');

    final bloc = context.read<ValueDetailBloc>();
    if (id == null) {
      bloc.add(
        ValueDetailEvent.create(
          name: name,
          color: color,
          priority: priority,
          iconName: iconName,
        ),
      );
    } else {
      bloc.add(
        ValueDetailEvent.update(
          id: id,
          name: name,
          color: color,
          priority: priority,
          iconName: iconName,
        ),
      );
    }
  }

  Future<void> _onDelete(String id) async {
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Value?',
      itemName: 'this value',
      description: 'Are you sure you want to delete this value?',
    );

    if (confirmed && mounted) {
      context.read<ValueDetailBloc>().add(ValueDetailEvent.delete(id: id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ValueDetailBloc, ValueDetailState>(
      listener: (context, state) {
        state.mapOrNull(
          operationSuccess: (success) {
            if (success.operation == EntityOperation.delete) {
              Navigator.of(context).pop(); // Close modal
            } else {
              Navigator.of(context).pop();
            }
          },
          operationFailure: (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  friendlyErrorMessage(
                    failure.errorDetails.error,
                  ),
                ),
              ),
            );
          },
        );
      },
      builder: (context, state) {
        return state.maybeMap(
          loadSuccess: (success) {
            _ensureFreshFormKeyFor(success.value.id);
            return ValueForm(
              formKey: _formKey,
              initialData: success.value,
              onSubmit: () => _onSubmit(success.value.id),
              onDelete: () => _onDelete(success.value.id),
              submitTooltip: 'Save Changes',
              onClose: () => Navigator.of(context).pop(),
            );
          },
          loadInProgress: (_) =>
              const Center(child: CircularProgressIndicator()),
          orElse: () {
            // Initial state or error state where we can still show the form for creation
            if (widget.valueId == null) {
              _ensureFreshFormKeyFor(null);
              return ValueForm(
                formKey: _formKey,
                initialData: null,
                onSubmit: () => _onSubmit(null),
                submitTooltip: 'Create Value',
                onClose: () => Navigator.of(context).pop(),
              );
            }
            return const Center(child: Text('Something went wrong'));
          },
        );
      },
    );
  }
}

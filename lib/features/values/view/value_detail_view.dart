import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/values/bloc/value_detail_bloc.dart';
import 'package:taskly_bloc/features/values/widgets/value_form.dart';

class ValueDetailSheetPage extends StatelessWidget {
  const ValueDetailSheetPage({
    required this.valueRepository,
    required this.onSuccess,
    required this.onError,
    this.valueId,
    super.key,
  });

  final ValueRepositoryContract valueRepository;
  final String? valueId;
  final void Function(String message) onSuccess;
  final void Function(String message) onError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => ValueDetailBloc(
          valueRepository: valueRepository,
          valueId: valueId,
        ),
        lazy: false,
        child: ValueDetailSheetView(
          onSuccess: onSuccess,
          onError: onError,
        ),
      ),
    );
  }
}

class ValueDetailSheetView extends StatefulWidget {
  const ValueDetailSheetView({
    required this.onSuccess,
    required this.onError,

    super.key,
  });

  final void Function(String message) onSuccess;
  final void Function(String message) onError;

  @override
  State<ValueDetailSheetView> createState() => _ValueDetailSheetViewState();
}

class _ValueDetailSheetViewState extends State<ValueDetailSheetView> {
  GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  String? _formValueId;

  void _ensureFreshFormKeyFor(String? valueId) {
    if (_formValueId == valueId) return;
    _formValueId = valueId;
    _formKey = GlobalKey<FormBuilderState>();
  }

  void _onSubmit(String? id) {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (formState.saveAndValidate()) {
      final formValues = formState.value;
      if (id == null) {
        context.read<ValueDetailBloc>().add(
          ValueDetailEvent.create(
            name: formValues['name'] as String,
          ),
        );
      } else {
        context.read<ValueDetailBloc>().add(
          ValueDetailEvent.update(
            id: id,
            name: formValues['name'] as String,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ValueDetailBloc, ValueDetailState>(
      listenWhen: (previous, current) {
        return current is ValueDetailOperationSuccess ||
            current is ValueDetailOperationFailure;
      },
      listener: (context, state) {
        switch (state) {
          case ValueDetailOperationSuccess(:final operation):
            final message = switch (operation) {
              EntityOperation.create => context.l10n.valueCreatedSuccessfully,
              EntityOperation.update => context.l10n.valueUpdatedSuccessfully,
              EntityOperation.delete => context.l10n.valueDeletedSuccessfully,
            };
            widget.onSuccess(message);
          case ValueDetailOperationFailure(:final errorDetails):
            widget.onError(
              friendlyErrorMessageForUi(errorDetails.error, context.l10n),
            );
          default:
            return;
        }
      },
      buildWhen: (previous, current) {
        return current is ValueDetailInitial ||
            current is ValueDetailLoadInProgress ||
            current is ValueDetailLoadSuccess;
      },
      builder: (context, state) {
        switch (state) {
          case ValueDetailInitial():
            _ensureFreshFormKeyFor(null);
            return ValueForm(
              initialData: null,
              formKey: _formKey,
              onSubmit: () => _onSubmit(null),
              submitTooltip: context.l10n.actionCreate,
            );
          case ValueDetailLoadInProgress():
            return const Center(child: CircularProgressIndicator());
          case ValueDetailLoadSuccess(:final value):
            // Use a fresh form key when loading existing data so the
            // FormBuilder picks up the provided initial values.
            _ensureFreshFormKeyFor(value.id);
            return ValueForm(
              initialData: value,
              formKey: _formKey,
              onSubmit: () => _onSubmit(value.id),
              submitTooltip: context.l10n.actionUpdate,
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

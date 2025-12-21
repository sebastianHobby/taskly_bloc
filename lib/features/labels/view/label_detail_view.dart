import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/features/labels/bloc/label_detail_bloc.dart';
import 'package:taskly_bloc/features/labels/widgets/label_form.dart';

class LabelDetailSheetPage extends StatelessWidget {
  const LabelDetailSheetPage({
    required this.labelRepository,
    required this.onSuccess,
    required this.onError,
    this.labelId,
    super.key,
  });

  final LabelRepositoryContract labelRepository;
  final String? labelId;
  final void Function(String message) onSuccess;
  final void Function(String message) onError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => LabelDetailBloc(
          labelRepository: labelRepository,
          labelId: labelId,
        ),
        lazy: false,
        child: LabelDetailSheetView(
          onSuccess: onSuccess,
          onError: onError,
        ),
      ),
    );
  }
}

class LabelDetailSheetView extends StatefulWidget {
  const LabelDetailSheetView({
    required this.onSuccess,
    required this.onError,
    super.key,
  });

  final void Function(String message) onSuccess;
  final void Function(String message) onError;

  @override
  State<LabelDetailSheetView> createState() => _LabelDetailSheetViewState();
}

class _LabelDetailSheetViewState extends State<LabelDetailSheetView> {
  GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  String? _formLabelId;

  void _ensureFreshFormKeyFor(String? labelId) {
    if (_formLabelId == labelId) return;
    _formLabelId = labelId;
    _formKey = GlobalKey<FormBuilderState>();
  }

  void _onSubmit(String? id) {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.saveAndValidate()) return;

    final formValues = formState.value;
    final name = formValues['name'] as String;

    if (id == null) {
      context.read<LabelDetailBloc>().add(LabelDetailEvent.create(name: name));
    } else {
      context.read<LabelDetailBloc>().add(
        LabelDetailEvent.update(id: id, name: name),
      );
    }
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
          case LabelDetailOperationSuccess(:final message):
            widget.onSuccess(message);
          case LabelDetailOperationFailure(:final errorDetails):
            widget.onError(
              friendlyErrorMessageForUi(errorDetails.error, context.l10n),
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
              formKey: _formKey,
              onSubmit: () => _onSubmit(null),
              submitTooltip: 'Create',
            );
          case LabelDetailLoadInProgress():
            return const Center(child: CircularProgressIndicator());
          case LabelDetailLoadSuccess(:final label):
            _ensureFreshFormKeyFor(label.id);
            return LabelForm(
              initialData: label,
              formKey: _formKey,
              onSubmit: () => _onSubmit(label.id),
              submitTooltip: 'Update',
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

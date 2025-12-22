import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/features/labels/bloc/label_detail_bloc.dart';
import 'package:taskly_bloc/features/labels/widgets/label_form.dart';

class LabelDetailSheetPage extends StatelessWidget {
  const LabelDetailSheetPage({
    required this.labelRepository,
    required this.onSuccess,
    required this.onError,
    this.labelId,
    this.initialType,
    this.lockType = false,
    super.key,
  });

  final LabelRepositoryContract labelRepository;
  final String? labelId;
  final LabelType? initialType;
  final bool lockType;
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
          initialType: initialType,
          lockType: lockType,
        ),
      ),
    );
  }
}

class LabelDetailSheetView extends StatefulWidget {
  const LabelDetailSheetView({
    required this.onSuccess,
    required this.onError,
    this.initialType,
    this.lockType = false,
    super.key,
  });

  final void Function(String message) onSuccess;
  final void Function(String message) onError;
  final LabelType? initialType;
  final bool lockType;

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

  void _onSubmit(String? id, {LabelType? existingType}) {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.saveAndValidate()) return;

    final formValues = formState.value;
    final name = formValues['name'] as String;
    final color = formValues['colour'] as String;
    final type = widget.lockType
        ? (widget.initialType ?? existingType ?? LabelType.label)
        : (formValues['type'] as LabelType);

    if (id == null) {
      context.read<LabelDetailBloc>().add(
        LabelDetailEvent.create(name: name, color: color, type: type),
      );
    } else {
      context.read<LabelDetailBloc>().add(
        LabelDetailEvent.update(id: id, name: name, color: color, type: type),
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
            widget.onSuccess(_successMessageFor(operation, context.l10n));
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
              initialType: widget.initialType,
              lockType: widget.lockType,
              formKey: _formKey,
              onSubmit: () => _onSubmit(null),
              submitTooltip: context.l10n.actionCreate,
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
              submitTooltip: context.l10n.actionUpdate,
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

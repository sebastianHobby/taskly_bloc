import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_domain/attention.dart';

sealed class AttentionRulesState {
  const AttentionRulesState();
}

final class AttentionRulesLoading extends AttentionRulesState {
  const AttentionRulesLoading();
}

final class AttentionRulesLoaded extends AttentionRulesState {
  const AttentionRulesLoaded(this.rules);

  final List<AttentionRule> rules;
}

final class AttentionRulesError extends AttentionRulesState {
  const AttentionRulesError(this.message);

  final String message;
}

class AttentionRulesCubit extends Cubit<AttentionRulesState> {
  AttentionRulesCubit({required AttentionRepositoryContract repository})
    : _repository = repository,
      super(const AttentionRulesLoading()) {
    _subscribe();
  }

  final AttentionRepositoryContract _repository;

  StreamSubscription<List<AttentionRule>>? _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }

  Future<void> toggleRule(AttentionRule rule) async {
    final previous = state;
    try {
      await _repository.updateRuleActive(rule.id, !rule.active);
    } catch (e) {
      emit(AttentionRulesError('Error updating rule: $e'));
      // Keep UI usable; next DB emission should re-load.
      emit(previous);
    }
  }

  void _subscribe() {
    _sub = _repository.watchAllRules().listen(
      (rules) {
        emit(AttentionRulesLoaded(rules));
      },
      onError: (Object e) {
        emit(AttentionRulesError('Error loading rules: $e'));
      },
    );
  }
}

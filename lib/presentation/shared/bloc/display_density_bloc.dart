import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';

@immutable
final class DisplayDensityState {
  const DisplayDensityState({required this.density});

  final DisplayDensity density;
}

sealed class DisplayDensityEvent {
  const DisplayDensityEvent();
}

final class DisplayDensityStarted extends DisplayDensityEvent {
  const DisplayDensityStarted();
}

final class DisplayDensityToggled extends DisplayDensityEvent {
  const DisplayDensityToggled();
}

final class DisplayDensitySet extends DisplayDensityEvent {
  const DisplayDensitySet(this.density);

  final DisplayDensity density;
}

class DisplayDensityBloc
    extends Bloc<DisplayDensityEvent, DisplayDensityState> {
  DisplayDensityBloc({
    required SettingsRepositoryContract settingsRepository,
    required PageKey pageKey,
    required DisplayDensity defaultDensity,
  }) : _settingsRepository = settingsRepository,
       _pageKey = pageKey,
       _defaultDensity = defaultDensity,
       super(DisplayDensityState(density: defaultDensity)) {
    on<DisplayDensityStarted>(_onStarted);
    on<DisplayDensityToggled>(_onToggled);
    on<DisplayDensitySet>(_onSet);
  }

  final SettingsRepositoryContract _settingsRepository;
  final PageKey _pageKey;
  final DisplayDensity _defaultDensity;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  Future<void> _onStarted(
    DisplayDensityStarted event,
    Emitter<DisplayDensityState> emit,
  ) async {
    final saved = await _settingsRepository.load(
      SettingsKey.pageDisplay(_pageKey),
    );
    final density = saved?.density ?? _defaultDensity;
    if (density != state.density) {
      emit(DisplayDensityState(density: density));
    }
  }

  Future<void> _onToggled(
    DisplayDensityToggled event,
    Emitter<DisplayDensityState> emit,
  ) async {
    final next = state.density == DisplayDensity.compact
        ? DisplayDensity.standard
        : DisplayDensity.compact;
    await _persistDensity(next);
    emit(DisplayDensityState(density: next));
  }

  Future<void> _onSet(
    DisplayDensitySet event,
    Emitter<DisplayDensityState> emit,
  ) async {
    if (event.density == state.density) return;
    await _persistDensity(event.density);
    emit(DisplayDensityState(density: event.density));
  }

  Future<void> _persistDensity(DisplayDensity density) async {
    final context = _contextFactory.create(
      feature: 'display_density',
      screen: _pageKey.key,
      intent: 'display_density_changed',
      operation: 'settings.save.pageDisplay',
      extraFields: <String, Object?>{
        'pageKey': _pageKey.key,
        'density': density.name,
      },
    );
    try {
      await _settingsRepository.save(
        SettingsKey.pageDisplay(_pageKey),
        DisplayPreferences(density: density),
        context: context,
      );
    } catch (error, stackTrace) {
      AppLog.handleStructured(
        'settings.display_density',
        'persist failed',
        error,
        stackTrace,
        context.toLogFields(),
      );
      // Non-fatal: keep UI responsive even if persistence fails.
    }
  }
}

@Tags(['unit'])
library;

import 'package:taskly_bloc/core/notifications/notification_permission_service.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/notification_permission_bloc.dart';

import '../../../helpers/test_imports.dart';

class _FakeNotificationPermissionService
    implements NotificationPermissionService {
  _FakeNotificationPermissionService({
    required this.initialStatus,
    required this.requestStatus,
  });

  final NotificationPermissionStatus initialStatus;
  final NotificationPermissionStatus requestStatus;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<NotificationPermissionStatus> getStatus() async => initialStatus;

  @override
  Future<void> openSettings() async {
    openSettingsCalls += 1;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requestCalls += 1;
    return requestStatus;
  }
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  blocTestSafe<NotificationPermissionBloc, NotificationPermissionState>(
    'loads denied status then emits granted after requesting permission',
    build: () {
      return NotificationPermissionBloc(
        permissionService: _FakeNotificationPermissionService(
          initialStatus: NotificationPermissionStatus.denied,
          requestStatus: NotificationPermissionStatus.granted,
        ),
      );
    },
    act: (bloc) async {
      bloc
        ..add(const NotificationPermissionStarted())
        ..add(const NotificationPermissionRequestRequested());
    },
    expect: () => const <NotificationPermissionState>[
      NotificationPermissionState(
        status: NotificationPermissionStatus.denied,
        isLoading: true,
      ),
      NotificationPermissionState(
        status: NotificationPermissionStatus.denied,
        isLoading: false,
      ),
      NotificationPermissionState(
        status: NotificationPermissionStatus.denied,
        isLoading: true,
      ),
      NotificationPermissionState(
        status: NotificationPermissionStatus.granted,
        isLoading: false,
        requestsCompleted: 1,
      ),
    ],
  );

  testSafe('open settings delegates to the permission service', () async {
    final service = _FakeNotificationPermissionService(
      initialStatus: NotificationPermissionStatus.denied,
      requestStatus: NotificationPermissionStatus.denied,
    );
    final bloc = NotificationPermissionBloc(permissionService: service);
    addTearDown(bloc.close);

    bloc.add(const NotificationPermissionOpenSettingsRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(service.openSettingsCalls, 1);
  });
}

import 'dart:io' show Platform;

String localDevHostImplInternal() {
  // In an Android emulator, 127.0.0.1 points to the emulator itself.
  // 10.0.2.2 routes to the host machine's loopback interface.
  if (Platform.isAndroid) return '10.0.2.2';
  return '127.0.0.1';
}

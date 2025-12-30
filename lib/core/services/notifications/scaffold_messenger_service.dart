import 'package:flutter/material.dart';

/// Provides a global [ScaffoldMessengerState] for showing in-app messages.
///
/// This is used for web-only notifications where OS-level notifications are
/// either unavailable or undesirable.
class ScaffoldMessengerService {
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();
}

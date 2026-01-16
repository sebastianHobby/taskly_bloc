import 'package:flutter/foundation.dart';

enum AttentionSessionBannerSeverity { warning, critical }

@immutable
class AttentionSessionBannerVm {
  const AttentionSessionBannerVm({required this.severity});

  final AttentionSessionBannerSeverity severity;
}

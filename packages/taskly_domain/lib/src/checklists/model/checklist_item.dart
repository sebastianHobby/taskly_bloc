import 'package:flutter/foundation.dart';

@immutable
class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.parentId,
    required this.title,
    required this.sortIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String parentId;
  final String title;
  final int sortIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
}

@immutable
class ChecklistItemState {
  const ChecklistItemState({
    required this.itemId,
    required this.isChecked,
    this.checkedAt,
  });

  final String itemId;
  final bool isChecked;
  final DateTime? checkedAt;
}

@immutable
class ChecklistProgress {
  const ChecklistProgress({
    required this.total,
    required this.checked,
  });

  final int total;
  final int checked;

  bool get allChecked => total > 0 && checked == total;
}

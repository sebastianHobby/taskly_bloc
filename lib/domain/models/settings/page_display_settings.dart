/// Display settings for a specific page.
class PageDisplaySettings {
  const PageDisplaySettings({
    this.hideCompleted = true,
    this.completedSectionCollapsed = false,
    this.showNextActionsBanner = true,
  });

  factory PageDisplaySettings.fromJson(Map<String, dynamic> json) {
    return PageDisplaySettings(
      hideCompleted: json['hideCompleted'] as bool? ?? true,
      completedSectionCollapsed:
          json['completedSectionCollapsed'] as bool? ?? false,
      showNextActionsBanner: json['showNextActionsBanner'] as bool? ?? true,
    );
  }

  final bool hideCompleted;
  final bool completedSectionCollapsed;
  final bool showNextActionsBanner;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'hideCompleted': hideCompleted,
    'completedSectionCollapsed': completedSectionCollapsed,
    'showNextActionsBanner': showNextActionsBanner,
  };

  PageDisplaySettings copyWith({
    bool? hideCompleted,
    bool? completedSectionCollapsed,
    bool? showNextActionsBanner,
  }) {
    return PageDisplaySettings(
      hideCompleted: hideCompleted ?? this.hideCompleted,
      completedSectionCollapsed:
          completedSectionCollapsed ?? this.completedSectionCollapsed,
      showNextActionsBanner:
          showNextActionsBanner ?? this.showNextActionsBanner,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageDisplaySettings &&
        other.hideCompleted == hideCompleted &&
        other.completedSectionCollapsed == completedSectionCollapsed &&
        other.showNextActionsBanner == showNextActionsBanner;
  }

  @override
  int get hashCode => Object.hash(
    hideCompleted,
    completedSectionCollapsed,
    showNextActionsBanner,
  );
}

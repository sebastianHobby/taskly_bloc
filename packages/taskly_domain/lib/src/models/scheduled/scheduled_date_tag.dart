/// Date tag for a scheduled occurrence.
///
/// This matches the Scheduled feed semantics:
/// - `due`: deadline is on this day
/// - `starts`: start is on this day
/// - `ongoing`: day is strictly between start and deadline
enum ScheduledDateTag {
  starts,
  ongoing,
  due;

  String get label => switch (this) {
    ScheduledDateTag.starts => 'Starts',
    ScheduledDateTag.ongoing => 'Ongoing',
    ScheduledDateTag.due => 'Due',
  };
}

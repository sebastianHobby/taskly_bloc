/// Types of task statistics available
enum TaskStatType {
  totalCount,
  completedCount,
  completionRate,
  staleCount, // No activity for 14+ days
  overdueCount,
  avgDaysToComplete,
  completedThisWeek,
  velocity, // Tasks completed per week
}

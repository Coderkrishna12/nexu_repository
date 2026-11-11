enum TaskPriority {
  low,
  normal,
  high;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'High';
    }
  }

  static TaskPriority fromString(String? value) {
    if (value == null) return TaskPriority.normal;
    switch (value.trim().toLowerCase()) {
      case 'high':
      case 'urgent':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'normal':
      case 'medium':
      default:
        return TaskPriority.normal;
    }
  }
}


enum ConfidenceLevel {
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case ConfidenceLevel.high:
        return 'High';
      case ConfidenceLevel.medium:
        return 'Medium';
      case ConfidenceLevel.low:
        return 'Low';
    }
  }

  static ConfidenceLevel fromString(String? value) {
    if (value == null) return ConfidenceLevel.low;
    switch (value.trim().toLowerCase()) {
      case 'high':
        return ConfidenceLevel.high;
      case 'medium':
        return ConfidenceLevel.medium;
      case 'low':
      default:
        return ConfidenceLevel.low;
    }
  }
}


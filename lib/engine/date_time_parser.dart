class ParsedDateTimeResult {
  final DateTime? date; // Date component (year, month, day)
  final int? timeMinutes; // Minutes from midnight (e.g. 5:00 PM -> 1020, 9:00 AM -> 540)
  final bool hasExplicitDate;
  final bool hasExplicitTime;
  final List<String> matchedTokens;
  final String cleanedText; // Text with date/time tokens removed

  const ParsedDateTimeResult({
    this.date,
    this.timeMinutes,
    required this.hasExplicitDate,
    required this.hasExplicitTime,
    required this.matchedTokens,
    required this.cleanedText,
  });
}

class DateTimeParser {
  static const Map<String, int> _weekdayMap = {
    'monday': DateTime.monday,
    'mon': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'tue': DateTime.tuesday,
    'tues': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'wed': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'thu': DateTime.thursday,
    'thur': DateTime.thursday,
    'thurs': DateTime.thursday,
    'friday': DateTime.friday,
    'fri': DateTime.friday,
    'saturday': DateTime.saturday,
    'sat': DateTime.saturday,
    'sunday': DateTime.sunday,
    'sun': DateTime.sunday,
  };

  static const Map<String, int> _monthMap = {
    'january': 1, 'jan': 1,
    'february': 2, 'feb': 2,
    'march': 3, 'mar': 3,
    'april': 4, 'apr': 4,
    'may': 5,
    'june': 6, 'jun': 6,
    'july': 7, 'jul': 7,
    'august': 8, 'aug': 8,
    'september': 9, 'sep': 9, 'sept': 9,
    'october': 10, 'oct': 10,
    'november': 11, 'nov': 11,
    'december': 12, 'dec': 12,
  };

  /// Parses date and time from [input] relative to [demoClock].
  static ParsedDateTimeResult parse(String input, DateTime demoClock) {
    String text = input.trim();
    final List<String> matchedTokens = [];
    DateTime? resolvedDate;
    int? resolvedTimeMinutes;
    bool hasExplicitDate = false;
    bool hasExplicitTime = false;

    // 1. Check for relative dates: "tomorrow" / "today"
    final tomorrowRegex = RegExp(r'\b(tomorrow)\b', caseSensitive: false);
    final todayRegex = RegExp(r'\b(today)\b', caseSensitive: false);

    if (tomorrowRegex.hasMatch(text)) {
      hasExplicitDate = true;
      final tomorrow = demoClock.add(const Duration(days: 1));
      resolvedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      matchedTokens.add('tomorrow');
      text = text.replaceAll(tomorrowRegex, ' ');
    } else if (todayRegex.hasMatch(text)) {
      hasExplicitDate = true;
      resolvedDate = DateTime(demoClock.year, demoClock.month, demoClock.day);
      matchedTokens.add('today');
      text = text.replaceAll(todayRegex, ' ');
    }

    // 2. Check for weekdays: "next Friday", "this Friday", "Friday"
    if (!hasExplicitDate) {
      final weekdayRegex = RegExp(
        r'\b(?:(next|this)\s+)?(monday|mon|tuesday|tue|tues|wednesday|wed|thursday|thu|thur|thurs|friday|fri|saturday|sat|sunday|sun)\b',
        caseSensitive: false,
      );
      final match = weekdayRegex.firstMatch(text);
      if (match != null) {
        final prefix = match.group(1)?.toLowerCase();
        final dayName = match.group(2)!.toLowerCase();
        final targetWeekday = _weekdayMap[dayName];
        if (targetWeekday != null) {
          hasExplicitDate = true;
          int daysToAdd = targetWeekday - demoClock.weekday;
          if (prefix == 'next') {
            daysToAdd = daysToAdd <= 0 ? daysToAdd + 7 : daysToAdd + 7;
          } else {
            // "Friday" or "this Friday"
            if (daysToAdd <= 0) {
              daysToAdd += 7; // Next occurrence
            }
          }
          final calculated = demoClock.add(Duration(days: daysToAdd));
          resolvedDate = DateTime(calculated.year, calculated.month, calculated.day);
          matchedTokens.add(match.group(0)!);
          text = text.replaceRange(match.start, match.end, ' ');
        }
      }
    }

    // 3. Check for specific date format (e.g. "12 nov", "nov 12", "12th november")
    if (!hasExplicitDate) {
      final datePattern1 = RegExp(
        r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:t|tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)(?:\s+(\d{4}))?\b',
        caseSensitive: false,
      );
      final match1 = datePattern1.firstMatch(text);
      if (match1 != null) {
        final day = int.parse(match1.group(1)!);
        final month = _monthMap[match1.group(2)!.toLowerCase()]!;
        final year = match1.group(3) != null ? int.parse(match1.group(3)!) : demoClock.year;
        hasExplicitDate = true;
        resolvedDate = DateTime(year, month, day);
        matchedTokens.add(match1.group(0)!);
        text = text.replaceRange(match1.start, match1.end, ' ');
      }
    }

    // 4. Parse time:
    // Formats:
    // - "at 5:30 pm", "at 5 pm", "at 5pm", "5:30 pm", "5 pm", "5pm"
    // - "at 10", "at 10 am", "10:00 am"
    // - "at 9:00", "at 9"
    final timeWithAmPmRegex = RegExp(
      r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );
    final timeWithAtOnlyRegex = RegExp(
      r'\bat\s+(\d{1,2})(?::(\d{2}))?\b',
      caseSensitive: false,
    );

    final amPmMatch = timeWithAmPmRegex.firstMatch(text);
    if (amPmMatch != null) {
      hasExplicitTime = true;
      int hour = int.parse(amPmMatch.group(1)!);
      final minute = amPmMatch.group(2) != null ? int.parse(amPmMatch.group(2)!) : 0;
      final meridian = amPmMatch.group(3)!.toLowerCase();

      if (meridian == 'pm' && hour < 12) {
        hour += 12;
      } else if (meridian == 'am' && hour == 12) {
        hour = 0;
      }

      resolvedTimeMinutes = hour * 60 + minute;
      matchedTokens.add(amPmMatch.group(0)!);
      text = text.replaceRange(amPmMatch.start, amPmMatch.end, ' ');
    } else {
      final atMatch = timeWithAtOnlyRegex.firstMatch(text);
      if (atMatch != null) {
        hasExplicitTime = true;
        int hour = int.parse(atMatch.group(1)!);
        final minute = atMatch.group(2) != null ? int.parse(atMatch.group(2)!) : 0;

        // Technician schedule heuristic:
        // 7, 8, 9, 10, 11 -> AM (e.g. "at 10" -> 10:00 AM)
        // 12 -> 12:00 PM (noon)
        // 1, 2, 3, 4, 5, 6 -> PM (e.g. "at 5" -> 5:00 PM)
        if (hour >= 1 && hour <= 6) {
          hour += 12;
        }

        resolvedTimeMinutes = hour * 60 + minute;
        matchedTokens.add(atMatch.group(0)!);
        text = text.replaceRange(atMatch.start, atMatch.end, ' ');
      }
    }

    // Clean up residual spaces
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedDateTimeResult(
      date: resolvedDate,
      timeMinutes: resolvedTimeMinutes,
      hasExplicitDate: hasExplicitDate,
      hasExplicitTime: hasExplicitTime,
      matchedTokens: matchedTokens,
      cleanedText: cleaned,
    );
  }

  /// Formats a DateTime cleanly (e.g. "Thu 12 Nov, 5:00 PM" or "Wed 11 Nov, 10:00 AM")
  static String formatFullDateTime(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final dayName = days[dt.weekday - 1];
    final dayNum = dt.day;
    final monthName = months[dt.month - 1];

    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';

    return '$dayName $dayNum $monthName, $hour12:$minuteStr $period';
  }

  /// Formats just date (e.g. "Thu 12 Nov")
  static String formatDateOnly(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}';
  }

  /// Formats just time (e.g. "5:00 PM" or "10:00 AM")
  static String formatTimeOnly(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minuteStr $period';
  }
}

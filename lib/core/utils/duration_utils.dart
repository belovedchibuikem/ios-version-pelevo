// lib/core/utils/duration_utils.dart

class DurationUtils {
  /// Converts duration string like "47m 27s" or "1h 23m" to total seconds
  static double parseDurationToSeconds(String durationStr) {
    if (durationStr.isEmpty) return 0.0;

    // Remove any extra spaces
    durationStr = durationStr.trim();

    double totalSeconds = 0.0;

    // Parse hours if present
    final hourMatch = RegExp(r'(\d+)h').firstMatch(durationStr);
    if (hourMatch != null) {
      totalSeconds += double.parse(hourMatch.group(1)!) * 3600;
    }

    // Parse minutes if present
    final minuteMatch = RegExp(r'(\d+)m').firstMatch(durationStr);
    if (minuteMatch != null) {
      totalSeconds += double.parse(minuteMatch.group(1)!) * 60;
    }

    // Parse seconds if present
    final secondMatch = RegExp(r'(\d+)s').firstMatch(durationStr);
    if (secondMatch != null) {
      totalSeconds += double.parse(secondMatch.group(1)!);
    }

    return totalSeconds;
  }

  /// Converts duration string like "47m 27s" to total minutes
  static double parseDurationToMinutes(String durationStr) {
    return parseDurationToSeconds(durationStr) / 60.0;
  }

  /// Formats seconds to duration string like "47m 27s"
  static String formatSecondsToString(double seconds) {
    final int totalSeconds = seconds.toInt();
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int remainingSeconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (remainingSeconds > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${minutes}m';
    }
  }

  /// Formats minutes to duration string like "47m"
  static String formatMinutesToString(double minutes) {
    final int totalMinutes = minutes.toInt();
    final int hours = totalMinutes ~/ 60;
    final int remainingMinutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  /// Formats duration from various formats to a consistent string format
  static String formatDuration(dynamic duration) {
    if (duration == null) return '';

    if (duration is String) {
      // If it's already a formatted string, return as is
      if (duration.contains('m') ||
          duration.contains('h') ||
          duration.contains('s')) {
        return duration;
      }
      // Try to parse as seconds
      try {
        final seconds = double.tryParse(duration);
        if (seconds != null) {
          return formatSecondsToString(seconds);
        }
      } catch (e) {
        // Ignore parsing errors
      }
      return duration;
    }

    if (duration is int || duration is double) {
      final seconds = duration.toDouble();
      if (seconds >= 60) {
        return formatSecondsToString(seconds);
      } else {
        return '${seconds.toInt()}s';
      }
    }

    return duration.toString();
  }
}

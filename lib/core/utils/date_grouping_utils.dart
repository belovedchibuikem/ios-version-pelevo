import 'package:intl/intl.dart';

class DateGroupingUtils {
  static String getDateGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final episodeDate = DateTime(date.year, date.month, date.day);

    if (episodeDate == today) {
      return 'TODAY';
    } else if (episodeDate == yesterday) {
      return 'YESTERDAY';
    } else {
      // Format as "AUGUST 13" style
      return DateFormat('MMMM d').format(date).toUpperCase();
    }
  }

  static Map<String, List<Map<String, dynamic>>> groupEpisodesByDate(
    List<Map<String, dynamic>> episodes,
  ) {
    final Map<String, List<Map<String, dynamic>>> groupedEpisodes = {};

    for (final episode in episodes) {
      DateTime? episodeDate;

      // Try to parse different date formats
      if (episode['releaseDate'] != null) {
        try {
          episodeDate = DateTime.parse(episode['releaseDate'].toString());
        } catch (e) {
          // Try alternative date formats if needed
        }
      }

      if (episode['publishDate'] != null) {
        try {
          episodeDate = DateTime.parse(episode['publishDate'].toString());
        } catch (e) {
          // Try alternative date formats if needed
        }
      }

      // If no valid date found, skip this episode
      if (episodeDate == null) continue;

      final header = getDateGroupHeader(episodeDate);

      if (!groupedEpisodes.containsKey(header)) {
        groupedEpisodes[header] = [];
      }

      groupedEpisodes[header]!.add(episode);
    }

    // Sort episodes within each group by date (newest first)
    for (final group in groupedEpisodes.values) {
      group.sort((a, b) {
        DateTime? dateA, dateB;

        try {
          dateA = DateTime.parse(a['releaseDate']?.toString() ??
              a['publishDate']?.toString() ??
              '');
          dateB = DateTime.parse(b['releaseDate']?.toString() ??
              b['publishDate']?.toString() ??
              '');
        } catch (e) {
          return 0;
        }

        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA); // Newest first
      });
    }

    return groupedEpisodes;
  }

  static List<String> getSortedDateHeaders(
      Map<String, List<Map<String, dynamic>>> groupedEpisodes) {
    final headers = groupedEpisodes.keys.toList();

    headers.sort((a, b) {
      // Custom sorting: TODAY, YESTERDAY, then by date
      if (a == 'TODAY') return -1;
      if (b == 'TODAY') return 1;
      if (a == 'YESTERDAY') return -1;
      if (b == 'YESTERDAY') return 1;

      // For other dates, sort by actual date (newest first)
      try {
        final dateA = DateFormat('MMMM d').parse(a.toLowerCase());
        final dateB = DateFormat('MMMM d').parse(b.toLowerCase());
        return dateB.compareTo(dateA);
      } catch (e) {
        return a.compareTo(b);
      }
    });

    return headers;
  }
}

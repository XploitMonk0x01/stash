import 'package:intl/intl.dart';

/// Utility for formatting dates in relative or absolute formats
class DateFormatter {
  DateFormatter._();

  /// Returns a human-readable relative time string
  /// e.g., "Just now", "2m ago", "3h ago", "Yesterday", "Mar 15"
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  /// Full date format: "March 15, 2026"
  static String fullDate(DateTime dateTime) {
    return DateFormat('MMMM d, yyyy').format(dateTime);
  }

  /// Short date: "Mar 15"
  static String shortDate(DateTime dateTime) {
    return DateFormat('MMM d').format(dateTime);
  }
}

import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class DateTimeUtil {
  static String convertTimestampToTimeAgo(var timestamp) {
    if (timestamp == null) {
      return '-';
    }

    var round = timestamp.round();
    final date = DateTime.fromMillisecondsSinceEpoch(round);

    return timeago.format(date);
  }

  static String convertTimestampToDate(var timestamp) {
    if (timestamp == null) {
      return '-';
    }

    final dateFormat = new DateFormat('dd.MM.yyyy hh:mm');
    var round = timestamp.round();
    final date = DateTime.fromMillisecondsSinceEpoch(round);

    return dateFormat.format(date);
  }

  static String convertTimestampToChatFriendlyDate(var timestamp) {
    String t = "-";

    if (timestamp != null) {
      var now = DateTime.now();
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp.round());

      var monthFormat = new DateFormat('MMM dd. hh:mm');
      var timeFormat = new DateFormat('hh:mm');
      var yearFormat = new DateFormat('yyyy.MM.dd hh:mm');

      if (date.year == now.year) {
        t = monthFormat.format(date);

        if (date.month == now.month) {
          if (date.day == now.day - 1) {
            t = 'Yesterday, ${timeFormat.format(date)}';

          } else if (date.day == now.day) {
            t = timeFormat.format(date);
          }
        }
      } else {
        t = yearFormat.format(date);
      }
    }

    return t;
  }
}

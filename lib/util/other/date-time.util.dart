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
    if (timestamp == null) {
      return '-';
    }

    var round = timestamp.round();
    final date = DateTime.fromMillisecondsSinceEpoch(round);

    var now = DateTime.now();
    var dateFormat = new DateFormat('hh:mm');
    var prefix = '';

    if (date.day == now.day - 1) {
      prefix = 'Yesterday, ';
    }

    return prefix + dateFormat.format(date);
  }
}

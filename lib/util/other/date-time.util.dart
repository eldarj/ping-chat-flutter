import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class DateTimeUtil {
  static String convertTimestampToTimeAgo(var timestamp) {
    if (timestamp == null) {
      return '-';
    }

    var round = timestamp.round();
    final date = DateTime.fromMillisecondsSinceEpoch(round * 1000);

    return timeago.format(date);
  }

  static String convertTimestampToDate(var timestamp) {
    if (timestamp == null) {
      return '-';
    }

    final dateFormat = new DateFormat('dd.MM.yyyy hh:mm');
    var round = timestamp.round();
    final date = DateTime.fromMillisecondsSinceEpoch(round * 1000);

    return dateFormat.format(date);
  }
}

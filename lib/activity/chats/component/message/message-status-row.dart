import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/util/other/date-time.util.dart';

class _MessageStatusRow extends StatelessWidget {
  final int timestamp;

  final bool sent;
  final bool received;
  final bool seen;

  final bool displayPlaceholderCheckmark;
  final bool displaySeen;

  final double iconSize = 13;

  const _MessageStatusRow({Key key, this.timestamp, this.sent, this.received, this.seen,
    this.displaySeen = true, this.displayPlaceholderCheckmark = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget statusIconWidget;

    if (displaySeen) {
      if (displayPlaceholderCheckmark) {
        statusIconWidget = Icon(Icons.check, color: Colors.grey, size: iconSize);
      } else if (seen) {
        statusIconWidget = Stack(children: [
          Icon(Icons.check, color: Colors.green, size: iconSize),
          Container(margin: EdgeInsets.only(left: 5), child: Icon(Icons.check, color: Colors.green, size: iconSize))
        ]);
      } else if (received) {
        statusIconWidget = Stack(children: [
          Icon(Icons.check, color: Colors.grey, size: iconSize),
          Container(margin: EdgeInsets.only(left: 5), child: Icon(Icons.check, color: Colors.grey, size: iconSize))
        ]);
      } else if (sent) {
        statusIconWidget = Icon(Icons.check, color: Colors.grey, size: iconSize);
      } else {
        statusIconWidget = Icon(Icons.hourglass_empty, color: Colors.grey, size: iconSize);
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        displaySeen ? Container(
            margin: EdgeInsets.only(right: 2.5),
            child: statusIconWidget
        ) : Container(),
        Text(DateTimeUtil.convertTimestampToChatFriendlyDate(timestamp),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      ],
    );
  }
}

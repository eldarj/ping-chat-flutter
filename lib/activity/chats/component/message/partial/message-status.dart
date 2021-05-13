import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart' show swidget;

class MessageTimestampLabel extends StatelessWidget {
  final int sentTimestamp;
  final Color textColor;
  final bool edited;

  const MessageTimestampLabel(this.sentTimestamp, this.textColor, {
    Key key,
    this.edited = false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(DateTimeUtil.convertTimestampToChatFriendlyDate(sentTimestamp), style: TextStyle(
            fontSize: 11,
            color: textColor
        )),
        edited != null && edited ? Container(
          padding: EdgeInsets.only(left: 5),
          child: Text('Edited', style: TextStyle(
              fontSize: 11,
              color: textColor
          )),
        ) : Container(),
      ]
    );
  }
}

class MessagePinnedLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 2.5, bottom: 2.5, left: 5, right: 5),
        child: Row(
          children: [
            Text('Pinned', style: TextStyle(
                fontSize: 11, color: Colors.grey.shade800)),
            Container(
                child: Icon(Icons.album_outlined, size: 8, color: CompanyColor.blueDark)),
          ],
        )
    );
  }
}

class MessageStatusIcon extends StatelessWidget {
  final dynamic sent;
  final dynamic received;
  final dynamic seen;

  final dynamic displayStatusIcon;
  final dynamic displayPlaceholderCheckMark;

  final Color iconColor;
  final Color seenIconColor;

  const MessageStatusIcon(this.sent, this.received, this.seen, {
    Key key,
    this.displayStatusIcon = true,
    this.displayPlaceholderCheckMark = false,
    this.iconColor,
    this.seenIconColor
  }) : super(key: key);

  @override
  Widget build(BuildContext _context) {
    Color iconColor = this.iconColor ?? Colors.grey.shade800;
    Color seenIconColor = this.seenIconColor ?? Colors.green;

    final double iconSize = 11;
    Widget statusIconWidget;

    if (displayPlaceholderCheckMark) {
      statusIconWidget = Icon(Icons.check, color: iconColor, size: iconSize);
    } else if (seen) {
      statusIconWidget = Stack(children: [
        Icon(Icons.check, color: iconColor, size: iconSize),
        Container(margin: EdgeInsets.only(left: 5), child: Icon(Icons.check, color: iconColor, size: iconSize))
      ]);
    } else if (received) {
      statusIconWidget = Stack(children: [
        Icon(Icons.check, color: seenIconColor, size: iconSize),
        Container(margin: EdgeInsets.only(left: 5), child: Icon(Icons.check, color: seenIconColor, size: iconSize))
      ]);
    } else if (sent) {
      statusIconWidget = Icon(Icons.check, color: iconColor, size: iconSize);
    } else {
      statusIconWidget = Icon(Icons.access_time, color: iconColor, size: iconSize);
    }

    return statusIconWidget;
  }
}


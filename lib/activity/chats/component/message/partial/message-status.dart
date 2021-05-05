import 'package:flutter/material.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart' show swidget;

part 'message-status.g.dart';

@swidget
Widget messageStatusRow(
    isPeerMessage,
    sentTimestamp,
    displayPlaceholderCheckMark,
    displayTimestamp,
    sent,
    received,
    seen
    ) {
  return displayTimestamp ? SizedOverflowBox(
      size: Size(50, 0),
      alignment: isPeerMessage
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Container(
        child: Container(
          child: isPeerMessage
              ? MessagePeerStatus(sentTimestamp)
              : MessageStatus(sentTimestamp, sent, received, seen, displayPlaceholderCheckMark: displayPlaceholderCheckMark),
        ),
        margin: EdgeInsets.only(left: 2.5, right: 2.5, top: 15),
      )) : Container();
}

@swidget
Widget messageStatus(sentTimestamp, sent, received, seen, {displayStatusIcon = true, displayPlaceholderCheckMark = false}) {
  final double iconSize = 11;
  Widget statusIconWidget;

  if (displayStatusIcon) {
    if (displayPlaceholderCheckMark) {
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
    children: [
      Container(
        margin: EdgeInsets.only(top: 2.5),
        padding: EdgeInsets.only(left: 2.5, right: 2.5, top: 1.5),
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.8),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(children: [
          displayStatusIcon ? Container(
              padding: EdgeInsets.only(right: 2.5),
              child: statusIconWidget
          ) : Container(),
          Container(
            child: Text(DateTimeUtil.convertTimestampToChatFriendlyDate(sentTimestamp),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          ),
        ]),
      ),
    ],
  );
}

@swidget
Widget messagePeerStatus(sentTimestamp) {
  return Container(
    margin: EdgeInsets.only(top: 2.5),
    padding: EdgeInsets.only(left: 2.5, right: 2.5, top: 1.5),
    decoration: BoxDecoration(
      color: Color.fromRGBO(255, 255, 255, 0.8),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(DateTimeUtil.convertTimestampToChatFriendlyDate(sentTimestamp),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
  );
}


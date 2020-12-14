
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/widget/message-status-row.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/other/date-time.util.dart';

class MessageBubble extends StatelessWidget {
  final bool isPeerMessage;

  final String content;

  final double maxWidth;

  final int sentTimestamp;
  final bool displayTimestamp;

  final bool sent;
  final bool received;
  final bool seen;
  final bool displayCheckMark;

  final bool isChained;

  const MessageBubble({Key key, this.isPeerMessage, this.content, this.sentTimestamp, this.displayTimestamp,
    this.maxWidth, this.sent, this.received, this.seen, this.displayCheckMark, this.isChained = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 10, right: 10, bottom: displayTimestamp ? 20 : 2.5),
      child: Column(crossAxisAlignment: isPeerMessage ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
                decoration: isPeerMessage ? peerBoxDecoration() : myBoxDecoration(),
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
                child: Text(content, style: TextStyle(fontSize: 16))),
            displayTimestamp ? SizedOverflowBox(
                alignment: isPeerMessage ? Alignment.centerLeft : Alignment.centerRight,
                size: Size(50, 0),
                child: Container(
                  margin: EdgeInsets.only(left: 2.5, right: 2.5, top: 15),
                  child: isPeerMessage ? peerMessageStatus() : myMessageStatus(),
                )) : Container(),
          ]),
    );
  }

  Widget peerMessageStatus() => Container(
    margin: EdgeInsets.only(left: 5),
    child: Text(DateTimeUtil.convertTimestampToChatFriendlyDate(sentTimestamp),
      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
    ),
  );

  Widget myMessageStatus() => Container(
    margin: EdgeInsets.only(right: 5),
    child: MessageStatusRow(timestamp: sentTimestamp,
        displayPlaceholderCheckmark: displayCheckMark,
        sent: sent, received: received, seen: seen),
  );

  BoxDecoration peerBoxDecoration() => BoxDecoration(
    color: Color.fromRGBO(239, 239, 239, 1),
    border: Border.all(color: Color.fromRGBO(234, 234, 234, 1), width: 1),
    borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isChained ? 15 : 0),
        bottomLeft: Radius.circular(15),
        topRight: Radius.circular(15),
        bottomRight: Radius.circular(15)),
    boxShadow: [BoxShadow(color: Colors.grey.shade300,
      offset: Offset.fromDirection(1, 0.3),
      blurRadius: 0, spreadRadius: 0,
    )],
  );

  BoxDecoration myBoxDecoration() => BoxDecoration(
    color: Color.fromRGBO(235, 255, 220, 1),
    border: Border.all(color: CompanyColor.myMessageBorder, width: 1),
    borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        bottomLeft: Radius.circular(15),
        topRight: Radius.circular(isChained ? 15 : 0),
        bottomRight: Radius.circular(15)),
    boxShadow: [BoxShadow(color: Colors.grey.shade300,
      offset: Offset.fromDirection(1, 0.3),
      blurRadius: 0, spreadRadius: 0,
    )],
  );
}

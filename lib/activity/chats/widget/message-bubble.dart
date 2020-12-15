
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

  final bool chained;

  final String messageType;

  const MessageBubble({Key key, this.isPeerMessage,
    this.content, this.sentTimestamp, this.displayTimestamp,
    this.maxWidth,
    this.sent, this.received, this.seen, this.displayCheckMark,
    this.chained = false,
    this.messageType
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget messageWidget;
    BoxDecoration messageDecoration;

    if (messageType == 'STICKER') {
      var stickerSize = MediaQuery.of(context).size.width / 3;
      messageWidget = Container(
          child: Image.asset('static/graphic/sticker/' + content, height: stickerSize, width: stickerSize));
      messageDecoration = stickerBoxDecoration();
    } else {
      messageWidget = Text(content, style: TextStyle(fontSize: 16));
      messageDecoration = isPeerMessage ? peerTextBoxDecoration() : myTextBoxDecoration();
    }


    return Container(
      margin: EdgeInsets.only(left: 10, right: 10, bottom: displayTimestamp ? 20 : 2.5),
      child: Column(crossAxisAlignment: isPeerMessage ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
                decoration: messageDecoration,
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: EdgeInsets.only(top: 7.5, bottom: 7.5, left: 10, right: 10),
                child: messageWidget),
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
    margin: EdgeInsets.only(left: 2.5),
    child: Text(DateTimeUtil.convertTimestampToChatFriendlyDate(sentTimestamp),
      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
    ),
  );

  Widget myMessageStatus() => Container(
    margin: EdgeInsets.only(right: 2.5),
    child: MessageStatusRow(timestamp: sentTimestamp,
        displayPlaceholderCheckmark: displayCheckMark,
        sent: sent, received: received, seen: seen),
  );

  BoxDecoration peerTextBoxDecoration() => BoxDecoration(
    color: Color.fromRGBO(239, 239, 239, 1),
    border: Border.all(color: Color.fromRGBO(234, 234, 234, 1), width: 1),
    borderRadius: BorderRadius.only(
        topLeft: Radius.circular(chained ? 15 : 0),
        bottomLeft: Radius.circular(10),
        topRight: Radius.circular(10),
        bottomRight: Radius.circular(10)),
    boxShadow: [BoxShadow(color: Colors.grey.shade300,
      offset: Offset.fromDirection(1, 0.3),
      blurRadius: 0, spreadRadius: 0,
    )],
  );

  BoxDecoration myTextBoxDecoration() => BoxDecoration(
    color: Color.fromRGBO(235, 255, 220, 1),
    border: Border.all(color: CompanyColor.myMessageBorder, width: 1),
    borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10),
        bottomLeft: Radius.circular(10),
        topRight: Radius.circular(chained ? 15 : 0),
        bottomRight: Radius.circular(15)),
    boxShadow: [BoxShadow(color: Colors.grey.shade300,
      offset: Offset.fromDirection(1, 0.3),
      blurRadius: 0, spreadRadius: 0,
    )],
  );

  BoxDecoration stickerBoxDecoration() => BoxDecoration(color: Colors.transparent);
}

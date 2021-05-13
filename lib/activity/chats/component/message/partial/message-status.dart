import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';
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
    seen,
    pinned,
    edited
    ) {
  return displayTimestamp ? SizedOverflowBox(
      size: Size(50, 0),
      alignment: isPeerMessage
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Container(
        child: Container(
          child: isPeerMessage
              ? MessagePeerStatus(sentTimestamp, pinned, edited)
              : MessageStatus(sentTimestamp, sent, received, seen, pinned, edited, displayPlaceholderCheckMark: displayPlaceholderCheckMark),
        ),
        margin: EdgeInsets.only(left: 2.5, right: 2.5, top: 15),
      )) : Container();
}

@swidget
Widget messageStatus(sentTimestamp, sent, received, seen, pinned, edited, {
  displayStatusIcon = true, displayPlaceholderCheckMark = false
}) {
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
        padding: EdgeInsets.only(left: 2.5, right: 5, top: 1.5),
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.8),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(children: [
          displayStatusIcon ? Container(
              padding: EdgeInsets.only(right: 2.5),
              margin: EdgeInsets.only(bottom: 1),
              child: statusIconWidget
          ) : Container(),
          Container(
            child: Row(
              children: [
                Text(DateTimeUtil.convertTimestampToChatFriendlyDate(sentTimestamp) + ' ',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 11)),
                Text(edited != null && edited ? '- Edited' : '', style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade800)),
                pinned != null && pinned ? Container(
                  child: Row(
                    children: [
                      Text('- Pinned', style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade800)),
                      Container(
                          margin: EdgeInsets.only(left: 1, bottom: 0.5),
                          child: Icon(Icons.album_outlined, size: 8, color: CompanyColor.blueDark)),
                    ],
                  )
                ) : Container(),
              ],
            ),
          ),
        ]),
      ),
    ],
  );
}

@swidget
Widget messagePeerStatus(sentTimestamp, pinned, edited) {
  return Flex(
    direction: Axis.horizontal,
    children: [
      Container(
        margin: EdgeInsets.only(top: 2.5),
        padding: EdgeInsets.only(left: 5, right: 5, top: 1.5),
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.8),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Text(DateTimeUtil.convertTimestampToChatFriendlyDate(sentTimestamp) + ' ',
                style: TextStyle(color: Colors.grey.shade800, fontSize: 11)),
            Text(edited != null && edited ? '- Edited' : '',
                style: TextStyle(color: Colors.grey.shade800, fontSize: 11)),
            pinned != null && pinned ? Container(
                child: Row(
                  children: [
                    Text('- Pinned', style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade800)),
                    Container(
                        margin: EdgeInsets.only(left: 1, bottom: 0.5),
                        child: Icon(Icons.album_outlined, size: 8, color: CompanyColor.blueDark)),
                  ],
                )
            ) : Container(),
          ],
        ),
      )
    ]
  );
}


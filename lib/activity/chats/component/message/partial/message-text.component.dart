import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/component/message/partial/status-label.component.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/shared/var/global.var.dart';

const MESSAGE_PADDING = EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15);

class MessageText extends StatelessWidget {
  final MessageDto message;

  final MessageTheme messageTheme;

  final bool displayStatusIcon;

  const MessageText(this.message, {
    Key key,
    this.messageTheme,
    this.displayStatusIcon = true
  }) : super(key: key);

  @override
  Widget build(BuildContext _context) {
    Color textColor = Colors.grey.shade800;
    Color statusLabelColor = Colors.grey.shade500;
    Color seenIconColor = Colors.green;

    if (this.messageTheme != null) {
      textColor = this.messageTheme.textColor;
      statusLabelColor = this.messageTheme.statusLabelColor;
      seenIconColor = this.messageTheme.seenIconColor;
    }

    Widget statusIcon = Container();

    if (displayStatusIcon) {
      statusIcon = MessageStatusIcon(
        message.sent, message.received, message.seen,
        displayPlaceholderCheckMark: message.displayCheckMark,
        iconColor: statusLabelColor, seenIconColor: seenIconColor,
      );
    }

    return Container(
        padding: MESSAGE_PADDING,
        child: Wrap(
          spacing: 10,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              child: Text(message.text ?? '',
                  style: TextStyle(
                      fontSize: 16,
                      color: textColor
                  )
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 1.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      padding: EdgeInsets.only(right: 2.5),
                      margin: EdgeInsets.only(bottom: 1),
                      child: statusIcon),
                  MessageTimestampLabel(message.sentTimestamp, statusLabelColor, edited: message.edited)
                ],
              ),
            )
          ],
        ));
  }
}

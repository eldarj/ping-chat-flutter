import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/component/message/partial/status-label.component.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/shared/var/global.var.dart';

const MESSAGE_PADDING = EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15);

class MessageSticker extends StatelessWidget {
  final String stickerCode;

  final MessageDto message;

  final MessageTheme messageTheme;

  final bool displayStatusIcon;

  final bool displayTimestamp;

  const MessageSticker({
    Key key,
    this.stickerCode,
    this.message,
    this.messageTheme,
    this.displayStatusIcon = true,
    this.displayTimestamp = true
  }) : super(key: key);


  @override
  Widget build(BuildContext _context) {
    Color stickerLabelColor = Colors.grey.shade500;
    Color seenIconColor = Colors.green;

    if (this.messageTheme != null) {
      seenIconColor = this.messageTheme.seenIconColor;
    }

    Widget statusIcon = Container();

    if (displayStatusIcon) {
      statusIcon = MessageStatusIcon(
        message.sent, message.received, message.seen,
        displayPlaceholderCheckMark: message.displayCheckMark,
        iconColor: stickerLabelColor, seenIconColor: seenIconColor,
      );
    }

    double size = DEVICE_MEDIA_SIZE.width / 3;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
            padding: EdgeInsets.all(5),
            child: Image.asset('static/graphic/sticker/' + stickerCode, height: size, width: size)
        ),
        !displayTimestamp ? Container() : Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.50),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.only(left: 5, right: 5, top: 2.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  padding: EdgeInsets.only(right: 2.5),
                  margin: EdgeInsets.only(bottom: 1),
                  child: statusIcon),
              MessageTimestampLabel(message.sentTimestamp, stickerLabelColor, edited: message.edited)
            ],
          ),
        ),
      ],
    );
  }
}

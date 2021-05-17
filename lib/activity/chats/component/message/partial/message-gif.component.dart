import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/component/message/partial/message.decoration.dart';
import 'package:flutterping/activity/chats/component/message/partial/status-label.component.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/shared/var/global.var.dart';

const MESSAGE_PADDING = EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15);

class MessageGif extends StatelessWidget {
  final String url;

  final MessageDto message;

  final MessageTheme messageTheme;

  final bool displayStatusIcon;

  final bool isPeerMessage;

  const MessageGif({
    Key key,
    this.url,
    this.message,
    this.messageTheme,
    this.displayStatusIcon = true,
    this.isPeerMessage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext _context) {
    Color gifLabelColor = Colors.grey.shade500;
    Color seenIconColor = Colors.green;

    if (this.messageTheme != null) {
      seenIconColor = this.messageTheme.seenIconColor;
    }

    Widget statusIcon = Container();

    if (displayStatusIcon) {
      statusIcon = MessageStatusIcon(
        message.sent, message.received, message.seen,
        displayPlaceholderCheckMark: message.displayCheckMark,
        iconColor: gifLabelColor, seenIconColor: seenIconColor,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isPeerMessage ? 0 : IMAGE_BUBBLE_RADIUS),
        topRight: Radius.circular(!isPeerMessage ? 0 : IMAGE_BUBBLE_RADIUS),
        bottomLeft: Radius.circular(IMAGE_BUBBLE_RADIUS),
        bottomRight: Radius.circular(IMAGE_BUBBLE_RADIUS),
      ),
      child: Container(
        width: 200,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
                width: 200,
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: url,
                )
            ),
            Container(
              padding: EdgeInsets.only(left: 10, right: 12.5, top: 2.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('static/graphic/logo/giphy-logo.png', height: 7),
                  Row(children: [
                    Container(
                        padding: EdgeInsets.only(right: 2.5),
                        margin: EdgeInsets.only(bottom: 1),
                        child: statusIcon),
                    MessageTimestampLabel(message.sentTimestamp, gifLabelColor, edited: message.edited)
                  ])
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/component/message/message-status-row.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-content.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-decoration.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-status.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:http/http.dart' as http;

class MessageComponent extends StatefulWidget {
  final MessageDto message;

  final bool displayTimestamp;

  final EdgeInsets margin;

  final String picturesPath;

  final bool isPeerMessage;

  const MessageComponent({Key key, this.message, this.isPeerMessage, this.displayTimestamp, this.margin, this.picturesPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MessageComponentState();
}

class MessageComponentState extends State<MessageComponent> {
  ScaffoldState scaffold;

  double maxWidth = DEVICE_MEDIA_SIZE.width - 150;

  Function tapDownHandler;

  initTapDownHandler() {
    if (widget.message.deleted) {
      tapDownHandler = null;

    } else if (widget.message.messageType == 'IMAGE' && !widget.message.isUploading) {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.id.toString() + widget.message.fileName
          : widget.message.filePath;

      tapDownHandler = (TapDownDetails details) async {
        NavigatorUtil.push(context,
            ImageViewerActivity(message: widget.message, sender: widget.message.senderContactName,
                timestamp: widget.message.sentTimestamp,
                file: File(filePath)));
      };

    } else if (widget.message.messageType == 'STICKER') {
      tapDownHandler = (TapDownDetails details) {
        onMessageTapDown(details, widget.message, widget.isPeerMessage, [
          PopupMenuItem(
            value: 'DELETE',
            child: Text("Delete"),
          ),
        ]);
      };

    } else {
      tapDownHandler = (TapDownDetails details) {
        onMessageTapDown(details, widget.message, widget.isPeerMessage, [
          PopupMenuItem(
            value: 'EDITfixorremove',
            child: Text("Edit"),
          ),
          PopupMenuItem(
            value: 'DELETE',
            child: Text("Delete"),
          ),
        ]);
      };
    }
  }

  @override
  void initState() {
    super.initState();
    initTapDownHandler();
  }

  @override
  Widget build(BuildContext context) {
    scaffold = Scaffold.of(context);

    return GestureDetector(
      onTapDown: tapDownHandler,
      child: Container(
        margin: widget.margin,
        child: Container(
          margin: EdgeInsets.only(left: 5, right: 5, bottom: widget.displayTimestamp ? 20 : 2.5),
          child: Column(crossAxisAlignment: widget.isPeerMessage ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                buildMessageContent(maxWidth),
                MessageStatusRow(widget.isPeerMessage,
                    widget.message.sentTimestamp,
                    widget.message.displayCheckMark,
                    widget.displayTimestamp,
                    widget.message.sent,
                    widget.message.received,
                    widget.message.seen),
              ]),
        ),
      ),
    );
  }

  buildMessageContent(double maxWidth) {
    double size = maxWidth;

    Widget messageWidget;
    BoxDecoration messageDecoration;

    var messagePadding = EdgeInsets.only(top: 7.5, bottom: 7.5, left: 10, right: 10);

    if (widget.message.deleted) {
      size = 150;
      messageWidget = MessageDeleted();
      messageDecoration = widget.isPeerMessage ? peerTextBoxDecoration() : myTextBoxDecoration();

    } else if (widget.message.messageType == 'IMAGE') {
      size = DEVICE_MEDIA_SIZE.width / 1.25;
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.id.toString() + widget.message.fileName
          : widget.message.filePath;

      messagePadding = EdgeInsets.all(0);
      messageDecoration = imageDecoration();
      messageWidget = MessageImage(size, filePath, widget.isPeerMessage,
          widget.message.isDownloadingImage, widget.message.isUploading, widget.message.uploadProgress,
          widget.message.stopUploadFunc);

    } else if (widget.message.messageType == 'STICKER') {
      messageWidget = MessageSticker(widget.message.text);
      messageDecoration = stickerBoxDecoration();

    } else {
      messageWidget = MessageText(widget.message.text);
      messageDecoration = widget.isPeerMessage ? peerTextBoxDecoration() : myTextBoxDecoration();
    }

    return Container(
        decoration: messageDecoration,
        constraints: BoxConstraints(maxWidth: size),
        padding: messagePadding,
        child: messageWidget);
  }

  onMessageTapDown(TapDownDetails details, MessageDto message, bool isPeerMessage, items) async {
    FocusScope.of(context).requestFocus(new FocusNode());
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(isPeerMessage ? 0 : 1, details.globalPosition.dy, 0, 0),
      elevation: 8.0,
      items: items,
    ).then((value) {
      if (value == 'EDIT') {

      } else if (value == 'DELETE') {
        doDeleteMessage(message).then(onDeleteMessageSuccess, onError: onDeleteMessageError);
      }
    });
  }

  Future doDeleteMessage(message) async {
    String url = '/api/messages/' + message.id.toString();

    http.Response response = await HttpClientService.delete(url);

    if (response.statusCode != 200) {
      throw Exception();
    }

    return message;
  }

  onDeleteMessageSuccess(message) async {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('Izbrisali ste poruku.'));

    await Future.delayed(Duration(seconds: 2));

    message.deleted = true;
    wsClientService.messageDeletedPub.sendEvent(message, '/messages/deleted');
  }

  onDeleteMessageError(error) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }
}

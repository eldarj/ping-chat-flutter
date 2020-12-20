import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-content.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-decoration.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-status.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

class MessageComponent extends StatefulWidget {
  final MessageDto message;

  final bool displayTimestamp;

  final EdgeInsets margin;

  final String picturesPath;

  final bool isPeerMessage;

  const MessageComponent({Key key,
    this.message,
    this.isPeerMessage,
    this.displayTimestamp,
    this.margin,
    this.picturesPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MessageComponentState();
}

class MessageComponentState extends State<MessageComponent> {
  ScaffoldState scaffold;

  double maxWidth = DEVICE_MEDIA_SIZE.width - 150;

  @override
  Widget build(BuildContext context) {
    scaffold = Scaffold.of(context);

    return GestureDetector(
      onTapDown: resolveMessageTapHandler(),
      child: Container(
        margin: widget.margin,
        child: Container(
          margin: EdgeInsets.only(left: 5, right: 5, bottom: widget.displayTimestamp ? 20 : 2.5),
          child: Column(crossAxisAlignment: widget.isPeerMessage ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                buildMessageContent(),
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

  buildMessageMedia(MessageDto message, filePath, isDownloadingFile, isUploading, uploadProgress, stopUploadFunc) {
    return Container(
        constraints: BoxConstraints(maxWidth: maxWidth, minWidth: maxWidth),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 10),
              child: isUploading ? GestureDetector(onTap: stopUploadFunc, child: Container(
                  width: 50, height: 50, child: UploadProgressIndicator(size: 50, progress: uploadProgress))) :
              isDownloadingFile ? Container(height: 50, width: 50,
                  alignment: Alignment.center,
                  child: Spinner()) :
              Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.blueGrey),
                  ),
                  child: Icon(Icons.ondemand_video, color: Colors.blueGrey)),
            ),
            Container(
              width: maxWidth - 100,
              alignment: Alignment.center,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(message.fileName + widget.message.messageType),
                    Text(message.fileSizeFormatted(), style: TextStyle(color: Colors.grey)),
                  ]),
            )
          ],
        ));
  }

  buildMessageContent() {
    Widget _messageWidget;

    BoxDecoration messageDecoration = widget.isPeerMessage ? peerTextBoxDecoration() : myTextBoxDecoration();

    if (widget.message.deleted) {
      _messageWidget = MessageDeleted();

    } else if (['MEDIA', 'FILE'].contains(widget.message.messageType??'')) {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.id.toString() + widget.message.fileName
          : widget.message.filePath;

      _messageWidget = buildMessageMedia(widget.message, filePath, widget.message.isDownloadingFile,
          widget.message.isUploading, widget.message.uploadProgress, widget.message.stopUploadFunc);

    } else if (widget.message.messageType == 'IMAGE') {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.id.toString() + widget.message.fileName
          : widget.message.filePath;

      _messageWidget = MessageImage(filePath, widget.message.isDownloadingFile, widget.message.isUploading,
          widget.message.uploadProgress);
      messageDecoration = imageDecoration();

    } else if (widget.message.messageType == 'STICKER') {
      _messageWidget = MessageSticker(widget.message.text);
      messageDecoration = stickerBoxDecoration();

    } else {
      _messageWidget = MessageText(widget.message.text);
    }

    return Container(
        decoration: messageDecoration,
        constraints: BoxConstraints(maxWidth: maxWidth), // TODO: Check max height
        child: _messageWidget);
  }

  resolveMessageTapHandler() {
    Function messageTapHandler;

    if (widget.message.deleted) {
      messageTapHandler = (_) {};
    } else if (['MEDIA', 'FILE'].contains(widget.message.messageType??'')) {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.id.toString() + widget.message.fileName
          : widget.message.filePath;

      messageTapHandler = (_) async {
        OpenFile.open(filePath);
      };

    } else if (widget.message.messageType == 'IMAGE') {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.id.toString() + widget.message.fileName
          : widget.message.filePath;

      if (widget.message.isUploading) {
        messageTapHandler = (_) async {
          setState(() {
            widget.message.deleted = true;
            widget.message.isUploading = false;
          });
          widget.message.stopUploadFunc();
        };
      } else {
        messageTapHandler = (_) async {
          NavigatorUtil.push(context,
              ImageViewerActivity(message: widget.message, sender: widget.message.senderContactName,
                  timestamp: widget.message.sentTimestamp,
                  file: File(filePath)));
        };
      }

    } else if (widget.message.messageType == 'STICKER') {
      messageTapHandler = (details) {
        onMessageTapDown(details, widget.message, widget.isPeerMessage, [
          PopupMenuItem(value: 'DELETE', child: Text("Delete")),
        ]);
      };

    } else {
      messageTapHandler = (details) {
        onMessageTapDown(details, widget.message, widget.isPeerMessage, [
          PopupMenuItem(value: 'DELETE', child: Text("Delete")),
        ]);
      };
    }

    return messageTapHandler;
  }

  onMessageTapDown(details, MessageDto message, bool isPeerMessage, items) async {
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

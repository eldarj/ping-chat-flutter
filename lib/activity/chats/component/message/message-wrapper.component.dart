import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/component/message-status-row.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-decoration.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/other/date-time.util.dart';

class MessageWrapperComponent extends StatefulWidget {
  final MessageDto message;

  final bool displayTimestamp;

  final EdgeInsets margin;

  final String picturesPath;

  final bool isPeerMessage;

  const MessageWrapperComponent({Key key, this.message, this.isPeerMessage, this.displayTimestamp, this.margin, this.picturesPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MessageWrapperComponentState();
}

class MessageWrapperComponentState extends State<MessageWrapperComponent> {
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
        showMessageOptions(details, widget.message, widget.isPeerMessage, [
          PopupMenuItem(
            value: 'DELETE',
            child: Text("Delete"),
          ),
        ]);
      };

    } else {
      tapDownHandler = (TapDownDetails details) {
        showMessageOptions(details, widget.message, widget.isPeerMessage, [
          PopupMenuItem(
            value: 'EDIT',
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
                buildStatusRow(),
              ]),
        ),
      ),
    );
  }

  buildStatusRow() {
    Widget content;
    if (widget.isPeerMessage) {
      content = Text(DateTimeUtil.convertTimestampToChatFriendlyDate(widget.message.sentTimestamp),
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
    } else {
      content = MessageStatusRow(timestamp: widget.message.sentTimestamp,
          displayPlaceholderCheckmark: widget.message.displayCheckMark,
          sent: widget.message.sent, received: widget.message.received, seen: widget.message.seen);
    }

    return widget.displayTimestamp ? SizedOverflowBox(
        size: Size(50, 0),
        alignment: widget.isPeerMessage ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: EdgeInsets.only(left: 2.5, right: 2.5, top: 15),
          child: Container(
            child: content,
          ),
        )) : Container();
  }

  buildMessageContent(double maxWidth) {
    double size = maxWidth;

    Widget messageWidget;
    BoxDecoration messageDecoration;

    var messagePadding = EdgeInsets.only(top: 7.5, bottom: 7.5, left: 10, right: 10);

    if (widget.message.deleted) {
      size = 150;
      messageWidget = buildDeleted();
      messageDecoration = widget.isPeerMessage ? peerTextBoxDecoration() : myTextBoxDecoration();

    } else if (widget.message.messageType == 'IMAGE') {
      size = DEVICE_MEDIA_SIZE.width / 1.25;
      messageWidget = buildImage(size);
      messageDecoration = imageDecoration();
      messagePadding = EdgeInsets.all(0);

    } else if (widget.message.messageType == 'STICKER') {
      var stickerSize = DEVICE_MEDIA_SIZE.width / 3;
      messageWidget = buildSticker(stickerSize);
      messageDecoration = stickerBoxDecoration();

    } else {
      messageWidget = buildText();
      messageDecoration = widget.isPeerMessage ? peerTextBoxDecoration() : myTextBoxDecoration();
    }

    return Container(
        decoration: messageDecoration,
        constraints: BoxConstraints(maxWidth: size),
        padding: messagePadding,
        child: messageWidget);
  }

  buildText() {
    return Text(widget.message.text, style: TextStyle(fontSize: 16));
  }

  buildSticker(stickerSize) {
    return Container(
        child: Image.asset('static/graphic/sticker/' + widget.message.text, height: stickerSize, width: stickerSize)
    );
  }

  buildImage(size) {
    String filePath = widget.isPeerMessage
        ? widget.picturesPath + '/' + widget.message.id.toString() + widget.message.fileName
        : widget.message.filePath;

    bool fileExists = File(filePath).existsSync();

    Container image = Container(
        color: widget.isPeerMessage ? Colors.grey.shade100 : CompanyColor.myMessageBackground,
        constraints: BoxConstraints(
            maxWidth: size, maxHeight: size, minHeight: 100, minWidth: 100
        ),
        child: widget.message.isDownloadingImage ? Container(
            height: 50, width: 50,
            alignment: Alignment.center,
            child: Spinner())
            : fileExists ? Image.file(File(filePath), fit: BoxFit.cover)
            : Text('TODO: fixme' + widget.isPeerMessage.toString()));

    Widget colorFilteredImage;
    if (widget.message.isUploading) {
      colorFilteredImage = ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOver),
        child: image,
      );
    } else {
      colorFilteredImage = image;
    }

    return Container(
        child: Stack(alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: colorFilteredImage,
            ),
            widget.message.isUploading ? GestureDetector(
                onTap: widget.message.stopUploadFunc,
                child: Container(
                    width: 100, height: 100,
                    child: UploadProgressIndicator(size: 50, progress: widget.message.uploadProgress))) : Container(width: 0),
          ],
        ));
  }

  buildDeleted() {
    return Row(
        children: [
          Container(child: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 16)),
          Text('Poruka izbrisana', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade400))
        ]
    );
  }

  showMessageOptions(TapDownDetails details, MessageDto message, bool isPeerMessage, items) async {
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

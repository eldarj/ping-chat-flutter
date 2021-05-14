import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-decoration.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-status.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
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
          displayStatusIcon: true, displayPlaceholderCheckMark: message.displayCheckMark,
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
              child: Text(message.text,
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

class MessageGif extends StatelessWidget {
  final String url;

  final MessageDto message;

  final MessageTheme messageTheme;

  final bool displayStatusIcon;

  const MessageGif({
    Key key,
    this.url,
    this.message,
    this.messageTheme,
    this.displayStatusIcon = true
  }) : super(key: key);

  @override
  Widget build(BuildContext _context) {
    Color gifLabelColor = Colors.grey.shade300;
    Color seenIconColor = Colors.green;

    if (this.messageTheme != null) {
      seenIconColor = this.messageTheme.seenIconColor;
    }

    Widget statusIcon = Container();

    if (displayStatusIcon) {
      statusIcon = MessageStatusIcon(
        message.sent, message.received, message.seen,
        displayStatusIcon: true, displayPlaceholderCheckMark: message.displayCheckMark,
        iconColor: gifLabelColor, seenIconColor: seenIconColor,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 200,
        color: Colors.black,
        padding: EdgeInsets.only(bottom: 2.5),
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
                  Image.asset('static/graphic/logo/giphy-logo.png', height: 10),
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
        displayStatusIcon: true, displayPlaceholderCheckMark: message.displayCheckMark,
        iconColor: stickerLabelColor, seenIconColor: seenIconColor,
      );
    }

    double size = DEVICE_MEDIA_SIZE.width / 3;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
            child: Image.asset('static/graphic/sticker/' + stickerCode, height: size, width: size)
        ),
        Container(
          padding: EdgeInsets.only(left: 5, right: 5, top: 2.5),
          child: !displayTimestamp ? Container() : Row(
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

class MessageDeleted extends StatelessWidget {
  const MessageDeleted({Key key}) : super(key: key);

  @override
  Widget build(BuildContext _context) {
    return Container(
      padding: MESSAGE_PADDING,
      child: Row(
          children: [
            Container(child: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 16)),
            Text('Deleted', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade400))
          ]
      ),
    );
  }
}

class MessageImage extends StatelessWidget {
  final dynamic filePath;

  final dynamic isDownloadingFile;

  final dynamic isUploading;

  final dynamic uploadProgress;

  final Function stopUploadFunc;

  final double size = DEVICE_MEDIA_SIZE.width / 1.25;

  final String text;

  final Color textColor;

  final bool isPeerMessage;

  final bool chained;

  MessageImage(
      this.filePath,
      this.isDownloadingFile,
      this.isUploading,
      this.uploadProgress,
      this.stopUploadFunc,
      {
        Key key,
        this.text,
        this.textColor,
        this.chained = false,
        this.isPeerMessage = false,
      }
  ) : super(key: key);

  @override
  Widget build(BuildContext _context) {
    File file = File(filePath);
    bool isFileValid = file.existsSync() && file.lengthSync() > 0;

    Color textColor = this.textColor ?? Colors.grey.shade800;

    if (!isFileValid) {
      return Container(
          constraints: BoxConstraints(
              maxWidth: size, maxHeight: size, minHeight: 100, minWidth: 100),
          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400));
    }

    Container image = Container(
        constraints: BoxConstraints(
            maxWidth: size, maxHeight: size, minHeight: 100, minWidth: 100
        ),
        child: isDownloadingFile ? Container(
            height: 50, width: 50,
            alignment: Alignment.center,
            child: Spinner())
            : Image.file(file, fit: BoxFit.cover));

    Widget colorFilteredImage;
    if (isUploading) {
      colorFilteredImage = ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOver),
          child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: image
          )
      );
    } else {
      colorFilteredImage = image;
    }

    return Container(
        child: Stack(alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isPeerMessage ? 0 : IMAGE_BUBBLE_RADIUS),
                topRight: Radius.circular(!isPeerMessage ? 0 : IMAGE_BUBBLE_RADIUS),
                bottomLeft: Radius.circular(chained && isPeerMessage ? 5 : IMAGE_BUBBLE_RADIUS),
                bottomRight: Radius.circular(chained && !isPeerMessage ? 5 : IMAGE_BUBBLE_RADIUS),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                colorFilteredImage,
                !isUploading && text != null ? Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    padding: MESSAGE_PADDING,
                    child: Text(text, style: TextStyle(
                        fontSize: 16,
                        color: textColor
                    ))) : Container()
              ]),
            ),
            isUploading ? GestureDetector(
              onTap: stopUploadFunc,
              child: Container(
                  width: 100, height: 100,
                  child: UploadProgressIndicator(size: 50, progress: uploadProgress)),
            ) : Container(width: 0),
          ],
        ));
  }
}

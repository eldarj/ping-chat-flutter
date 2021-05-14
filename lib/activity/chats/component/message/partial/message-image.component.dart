import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/component/message/partial/message.decoration.dart';
import 'package:flutterping/activity/chats/component/message/partial/status-label.component.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:bordered_text/bordered_text.dart';

const MESSAGE_PADDING = EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15);

// TODO: Split into message image and location image
class MessageImage extends StatelessWidget {
  final dynamic filePath;

  final dynamic isDownloadingFile;
  final dynamic isUploading;
  final dynamic uploadProgress;

  final Function stopUploadFunc;

  final double size = DEVICE_MEDIA_SIZE.width / 1.25;

  final String text;

  final MessageDto message;
  final bool isPeerMessage;
  final Color textColor;
  final bool chained;

  final MessageTheme messageTheme;
  final bool displayStatusIcon;
  final bool displayText;

  MessageImage(
      this.message,
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
        this.messageTheme,
        this.displayStatusIcon = true,
        this.displayText = false,
      }
      ) : super(key: key);

  @override
  Widget build(BuildContext _context) {
    File file = File(filePath);
    bool isFileValid = file.existsSync() && file.lengthSync() > 0;

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
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Stack(alignment: Alignment.center,
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
                    !isUploading && displayText ? buildImageText() : Container()
                  ]),
                ),
                isUploading ? GestureDetector(
                  onTap: stopUploadFunc,
                  child: Container(
                      width: 100, height: 100,
                      child: UploadProgressIndicator(size: 50, progress: uploadProgress)),
                ) : Container(width: 0),
              ],
            ),
            !displayText ? buildStatusLabel() : Container(),
          ],
        ));
  }

  Widget buildStatusLabel() {
    Color seenIconColor = Colors.green;

    if (this.messageTheme != null) {
      seenIconColor = this.messageTheme.seenIconColor;
    }

    Widget statusIcon = Container();

    if (displayStatusIcon) {
      statusIcon = Container(
        child: MessageStatusIcon(
          message.sent, message.received, message.seen,
          displayPlaceholderCheckMark: message.displayCheckMark,
          iconColor: Colors.white, seenIconColor: seenIconColor,
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(right: 10, left: 10, bottom: 5),
      padding: EdgeInsets.only(left: 5, top: 3.5, bottom: 3.5, right: 10),
      decoration: BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.17),
          borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              padding: EdgeInsets.only(right: 2.5),
              margin: EdgeInsets.only(bottom: 1),
              child: statusIcon),
          MessageTimestampLabel(
              message.sentTimestamp,
              Colors.white,
              edited: message.edited,
          )
        ],
      ),
    );
  }

  Widget buildImageText() {
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
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Container(
        padding: MESSAGE_PADDING,
        child: Wrap(
          spacing: 10,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(text, style: TextStyle(
                fontSize: 16,
                color: textColor
            )),
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
        ),
      ),
    );
  }
}

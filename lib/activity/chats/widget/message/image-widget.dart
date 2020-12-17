
import 'dart:io';
import 'package:flutterping/activity/data-space/widget/image-viewer.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/widget/message-status-row.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/other/date-time.util.dart';

class ImageWidget extends StatelessWidget {
  BuildContext scaffold;

  final bool isPeerMessage;

  final bool displayTimestamp;

  final MessageDto message;

  double imageSize = 0;

  ImageWidget({Key key, this.isPeerMessage,
    this.message,
    this.displayTimestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    scaffold = context;
    imageSize = MediaQuery.of(context).size.width / 1.25;

    return Container(
      margin: EdgeInsets.only(left: 10, right: 10, bottom: 20),
      child: Column(crossAxisAlignment: isPeerMessage ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              child: Container(
                  child: Column(
                    children: [
                      isPeerMessage ? Container() : buildImageFromPath(message.filePath),
                    ],
                  )),
            ),
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

  Container peerMessageStatus() => Container(
    margin: EdgeInsets.only(left: 2.5),
    child: Text(DateTimeUtil.convertTimestampToChatFriendlyDate(message.sentTimestamp),
      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
    ),
  );

  Container myMessageStatus() => Container(
    margin: EdgeInsets.only(right: 2.5),
    child: MessageStatusRow(timestamp: message.sentTimestamp,
        displayPlaceholderCheckmark: message.displayCheckMark,
        sent: message.sent, received: message.received, seen: message.seen),
  );

  buildImageFromPath(String filePath) {
    Container image = Container(
        color: isPeerMessage ? Colors.grey.shade100 : CompanyColor.myMessageBackground,
        constraints: BoxConstraints(
            maxWidth: imageSize, maxHeight: imageSize, minHeight: 100, minWidth: 100
        ),
        child: Image.file(File(message.filePath, ), fit: BoxFit.cover));

    Widget wrappedImage;
    if (message.isUploading) {
      wrappedImage = ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOver),
        child: image,
      );
    } else {
      wrappedImage = Container(child: image);
    }

    return GestureDetector(
      onTap: !message.isUploading ? () {
        NavigatorUtil.push(scaffold, ImageViewer(file: File(message.filePath)));
      } : null,
      child: Stack(alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: wrappedImage,
          ),
          message.isUploading ? GestureDetector(
              onTap: message.stopUploadFunc != null ? message.stopUploadFunc : () {
                print('WHAAAAAAAAAAT');
              },
              child: Container(
                  width: 100, height: 100,
                  child: UploadProgressIndicator(size: 50, progress: message.uploadProgress))) : Container(width: 0),
        ],
      ),
    );
  }
}

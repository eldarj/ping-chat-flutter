
import 'dart:io';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/component/message-status-row.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/other/date-time.util.dart';

class ImageMessageComponent extends StatelessWidget {
  BuildContext scaffold;

  final bool isPeerMessage;

  final bool displayTimestamp;

  final MessageDto message;

  final String picturesPath;

  double imageSize = 0;

  ImageMessageComponent({Key key, this.isPeerMessage,
    this.message,
    this.picturesPath,
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
            message.deleted ? buildDeletedItem() : buildImage(),
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

  Container buildImage() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
          child: Column(
            children: [
              isPeerMessage ? buildImageFromPath(picturesPath + '/' + message.id.toString() + message.fileName) : buildImageFromPath(message.filePath),
            ],
          )),
    );
  }

  buildDeletedItem() {
    return Container(
      child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          width: 200,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
              children: [
                Container(child: Icon(Icons.close, color: Colors.grey.shade400, size: 16)),
                Text('Poruka izbrisana', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade400))
              ]
          )),
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
    bool fileExists = File(filePath).existsSync();
    Container image = Container(
        color: isPeerMessage ? Colors.grey.shade100 : CompanyColor.myMessageBackground,
        constraints: BoxConstraints(
            maxWidth: imageSize, maxHeight: imageSize, minHeight: 100, minWidth: 100
        ),
        child: message.isDownloadingImage ? Container(
            height: 50, width: 50,
            alignment: Alignment.center,
            child: Spinner())
            : fileExists ? Image.file(File(filePath), fit: BoxFit.cover) : Text('TODO: fixme'));

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
      onTap: !message.isUploading ? () async {
        var result = await NavigatorUtil.push(scaffold,
            ImageViewerActivity(sender: message.senderContactName,
                timestamp: message.sentTimestamp,
                file: File(filePath)));
        if (result != null && result['deleted'] == true) {
          message.deleted = true;
          wsClientService.updateMessagePub.subject.add(message);
        }
      } : null,
      child: Stack(alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: wrappedImage,
          ),
          message.isUploading ? GestureDetector(
              onTap: message.stopUploadFunc,
              child: Container(
                  width: 100, height: 100,
                  child: UploadProgressIndicator(size: 50, progress: message.uploadProgress))) : Container(width: 0),
        ],
      ),
    );
  }
}

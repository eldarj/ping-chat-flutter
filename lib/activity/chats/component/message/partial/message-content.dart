import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/other/date-time.util.dart';

const MESSAGE_PADDING = EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15);

class MessageText extends StatelessWidget {
   final String text;
  final int timestamp;

  final bool edited;

  final Color textColor;

  const MessageText(this.text, this.timestamp, {
    Key key,
    this.edited = false,
    this.textColor
  }) : super(key: key);

  @override
  Widget build(BuildContext _context) {
    Color textColor = this.textColor ?? Colors.grey.shade800;
    return Container(
        padding: MESSAGE_PADDING,
        child: Wrap(
          alignment: WrapAlignment.end,
          children: [
            Container(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 16,
                      color: textColor
                  )
              ),
            ),
            Container(
              child: Text(DateTimeUtil.convertTimestampToChatFriendlyDate(timestamp),
                  style: TextStyle(
                      fontSize: 11,
                      color: textColor
                  )
              )
            )
          ],
        ));
  }
}

class MessageGif extends StatelessWidget {
  const MessageGif(this.url, {Key key}) : super(key: key);

  final dynamic url;

  @override
  Widget build(BuildContext _context) {
    double size = DEVICE_MEDIA_SIZE.width / 1.25;
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
              constraints: BoxConstraints(
                maxWidth: size, minWidth: 200,
              ),
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: url,
              )
          ),
        ),
        Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 1),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.only(left: 5, bottom: 2.5),
            padding: EdgeInsets.only(left: 5, right: 5, bottom: 2),
            child: Text('Giphy', style: TextStyle(
                fontSize: 9, color: Colors.grey.shade500,
                decoration: TextDecoration.underline
            ))),
      ],
    );
  }
}

class MessageSticker extends StatelessWidget {
  const MessageSticker(this.text, {Key key}) : super(key: key);

  final dynamic text;

  @override
  Widget build(BuildContext _context) {
    double size = DEVICE_MEDIA_SIZE.width / 3;
    return Container(
        child: Image.asset('static/graphic/sticker/' + text, height: size, width: size)
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

  final double borderRadius;

  final Color textColor;

  MessageImage(
      this.filePath,
      this.isDownloadingFile,
      this.isUploading,
      this.uploadProgress,
      this.stopUploadFunc,
      {
        Key key,
        this.text,
        this.borderRadius = 15,
        this.textColor
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
              borderRadius: BorderRadius.circular(borderRadius),
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

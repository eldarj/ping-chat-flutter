import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';

const MESSAGE_PADDING = EdgeInsets.only(top: 7.5, bottom: 7.5, left: 10, right: 10);

class MessageText extends StatelessWidget {
  const MessageText(this.text, {Key key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext _context) {
    return Container(
        padding: MESSAGE_PADDING,
        child: Text(text, style: TextStyle(fontSize: 16)));
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
  MessageImage(
      this.filePath,
      this.isDownloadingFile,
      this.isUploading,
      this.uploadProgress,
      this.stopUploadFunc,
      {Key key})
      : super(key: key);

  final dynamic filePath;

  final dynamic isDownloadingFile;

  final dynamic isUploading;

  final dynamic uploadProgress;

  final Function stopUploadFunc;

  final double size = DEVICE_MEDIA_SIZE.width / 1.25;

  @override
  Widget build(BuildContext _context) {
    bool fileExists = File(filePath).existsSync();

    Container image = Container(
        constraints: BoxConstraints(
            maxWidth: size, maxHeight: size, minHeight: 100, minWidth: 100
        ),
        child: isDownloadingFile ? Container(
            height: 50, width: 50,
            alignment: Alignment.center,
            child: Spinner())
            : fileExists ? Image.file(File(filePath), fit: BoxFit.cover)
            : Icon(Icons.broken_image_outlined, color: Colors.grey.shade400));

    Widget colorFilteredImage;
    if (isUploading) {
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

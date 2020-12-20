
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart' show swidget;

part 'message-content.g.dart';

@swidget
Widget messageText(String text) {
  return Text(text, style: TextStyle(fontSize: 16));
}

@swidget
Widget messageMedia() {
  return Container(child: Text('MEDIA'));
}

@swidget
Widget messageSticker(text) {
  double size = DEVICE_MEDIA_SIZE.width / 3;
  return Container(
      child: Image.asset('static/graphic/sticker/' + text, height: size, width: size)
  );
}

@swidget
Widget messageImage(size, filePath, isPeerMessage, isDownloadingFile, isUploading, uploadProgress) {
  bool fileExists = File(filePath).existsSync();

  Container image = Container(
      color: isPeerMessage ? Colors.grey.shade100 : CompanyColor.myMessageBackground,
      constraints: BoxConstraints(
          maxWidth: size, maxHeight: size, minHeight: 100, minWidth: 100
      ),
      child: isDownloadingFile ? Container(
          height: 50, width: 50,
          alignment: Alignment.center,
          child: Spinner())
          : fileExists ? Image.file(File(filePath), fit: BoxFit.cover)
          : Text('TODO: fixme' + isPeerMessage.toString()));

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
          isUploading ? Container(
              width: 100, height: 100,
              child: UploadProgressIndicator(size: 50, progress: uploadProgress)) : Container(width: 0),
        ],
      ));
}

@swidget
Widget messageDeleted() {
  return Row(
      children: [
        Container(child: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 16)),
        Text('Poruka izbrisana', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade400))
      ]
  );
}

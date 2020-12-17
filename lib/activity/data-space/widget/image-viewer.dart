import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewer extends StatelessWidget {
  final File file;

  ImageViewer({this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
        child: PhotoView(
          imageProvider: FileImage(file),
        )
    );
  }
}

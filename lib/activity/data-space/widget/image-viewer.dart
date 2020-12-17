import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewer extends StatelessWidget {
  final File file;

  const ImageViewer({Key key, this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: PhotoView(
          imageProvider: FileImage(file),
        )
    );
  }
}

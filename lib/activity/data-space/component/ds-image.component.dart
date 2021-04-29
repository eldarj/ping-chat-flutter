import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DSImage extends StatelessWidget {
  DSImage(
      this.filePath,
      {Key key})
      : super(key: key);

  final dynamic filePath;

  @override
  Widget build(BuildContext _context) {
    File file = File(filePath);
    bool isFileValid = file.existsSync() && file.lengthSync() > 0;

    return GestureDetector(
      onTap: () {},
      child: isFileValid ? Image.file(File(filePath), fit: BoxFit.cover)
          : Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
    );
  }
}

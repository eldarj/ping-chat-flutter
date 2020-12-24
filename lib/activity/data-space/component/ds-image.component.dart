
import 'package:flutter/cupertino.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';

class DSImage extends StatelessWidget {
  DSImage(
      this.filePath,
      {Key key})
      : super(key: key);

  final dynamic filePath;

  @override
  Widget build(BuildContext _context) {
    bool fileExists = File(filePath).existsSync();

    return GestureDetector(
      onTap: () {},
      child: fileExists ? Image.file(File(filePath), fit: BoxFit.cover)
          : Text('TODO: fixme'),
    );
  }
}

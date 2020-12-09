
import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

class Spinner extends StatelessWidget {
  final double strokeWidth;
  final Color color;

  Spinner({this.strokeWidth: 2.0, this.color: const Color.fromRGBO(28, 166, 197, 1)});

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
        strokeWidth: this.strokeWidth,
        backgroundColor: Colors.grey.shade300,
        valueColor: new AlwaysStoppedAnimation<Color>(color));
  }
}

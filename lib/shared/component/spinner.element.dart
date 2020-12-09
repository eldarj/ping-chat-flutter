
import 'package:flutter/material.dart';

class Spinner extends StatelessWidget {
  final double strokeWidth;
  final Color color;

  Spinner({this.strokeWidth: 2.0, this.color: Colors.lightBlue});

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
        strokeWidth: this.strokeWidth,
        backgroundColor: Colors.grey.shade300,
        valueColor: new AlwaysStoppedAnimation<Color>(color));
  }
}

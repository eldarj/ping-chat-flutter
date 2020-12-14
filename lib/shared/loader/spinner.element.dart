
import 'package:flutter/material.dart';

class Spinner extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;

  Spinner({this.strokeWidth: 2.0, this.size = 40,
    this.color: const Color.fromRGBO(28, 166, 197, 1)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: this.size, height: this.size,
      child: CircularProgressIndicator(
          strokeWidth: this.strokeWidth,
          backgroundColor: Colors.grey.shade300,
          valueColor: new AlwaysStoppedAnimation<Color>(color)),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Spinner extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final double padding;
  final bool visible;
  final Color backgroundColor;

  Spinner({
    this.strokeWidth: 2.0,
    this.size = 40,
    this.color: const Color.fromRGBO(28, 166, 197, 1),
    this.padding: 0,
    this.visible = true,
    this.backgroundColor = Colors.transparent
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 250),
      opacity: visible ? 1 : 0,
      child: Container(
        width: this.size, height: this.size,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle
        ),
        child: CircularProgressIndicator(
            strokeWidth: this.strokeWidth,
            backgroundColor: Colors.grey.shade300,
            valueColor: new AlwaysStoppedAnimation<Color>(color)),
      ),
    );
  }
}

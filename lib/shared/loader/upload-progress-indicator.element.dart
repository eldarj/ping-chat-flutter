
import 'package:flutter/material.dart';

class UploadProgressIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;

  final double value;

  UploadProgressIndicator({this.strokeWidth: 2.0, this.size = 40,
    this.value, this.color: const Color.fromRGBO(28, 166, 197, 1)});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: this.size, height: this.size,
              child: CircularProgressIndicator(
                  strokeWidth: this.strokeWidth,
                  backgroundColor: Colors.grey.shade300,
                  value: value != null ? value : null,
                  valueColor: new AlwaysStoppedAnimation<Color>(color)),
            ),
            Icon(Icons.close, color: Colors.white, size: 30)
          ],
        ),
      ),
    );
  }
}

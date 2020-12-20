
import 'package:flutter/material.dart';

class UploadProgressIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;

  final double progress;

  UploadProgressIndicator({this.strokeWidth: 2.0, this.size = 40,
    this.progress = 0.0, this.color: const Color.fromRGBO(28, 166, 197, 1)});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: this.size, height: this.size,
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                      strokeWidth: this.strokeWidth,
                      backgroundColor: Colors.grey.shade300,
                      value: value != null ? value : null,
                      valueColor: new AlwaysStoppedAnimation<Color>(color));
                },
              ),
            ),
            Icon(Icons.close, color: color, size: 30),
          ],
        ),
      ),
    );
  }
}

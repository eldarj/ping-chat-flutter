import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final String text;

  final GradientButtonBubbleDirection bubble;
  final Function onPressed;

  final Color color;

  const GradientButton({Key key, this.child, this.text, this.bubble: GradientButtonBubbleDirection.fromTopLeft,
    this.onPressed, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 7),
      height: 35,
      decoration: BoxDecoration(
        borderRadius: bubble.borderRadius,
        gradient: LinearGradient(
          colors: this.onPressed != null ? (this.color != null ? [this.color, this.color] : [CompanyColor.blueAccent, CompanyColor.bluePrimary])
              : [Colors.grey.shade100, CompanyColor.backgroundGrey],
          begin: FractionalOffset.bottomLeft,
          end: FractionalOffset.topRight,
        ),
      ),
      child: FlatButton(
        colorBrightness: Brightness.dark,
        child: text != null ? Text(text) : child,
        onPressed: onPressed,
      ),
    );
  }
}

enum GradientButtonBubbleDirection {
  fromTopLeft, fromTopRight, fromBottomLeft, fromBottomRight
}

extension GradientButtonBubbleDirectionExtension on GradientButtonBubbleDirection {
  BorderRadius get borderRadius {
    switch (this) {
      case GradientButtonBubbleDirection.fromBottomLeft:
        return BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        );
      case GradientButtonBubbleDirection.fromBottomRight:
        return BorderRadius.only(
          bottomLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        );
      case GradientButtonBubbleDirection.fromTopLeft:
        return BorderRadius.only(
          bottomLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      case GradientButtonBubbleDirection.fromTopRight:
        return BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        );
      default:
        return BorderRadius.all(Radius.circular(10));
    }
  }
}

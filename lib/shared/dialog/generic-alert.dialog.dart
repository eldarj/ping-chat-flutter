import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

class GenericAlertDialog extends StatelessWidget {
  final Color bgColor;
  final String title;
  final String message;
  final String positiveBtnText;
  final String negativeBtnText;
  final Function onPostivePressed;
  final Function onNegativePressed;
  final double circularBorderRadius;

  GenericAlertDialog({
    this.title,
    this.message,
    this.circularBorderRadius = 5.0,
    this.bgColor = Colors.white,
    this.positiveBtnText,
    this.negativeBtnText,
    this.onPostivePressed,
    this.onNegativePressed,
  })  : assert(bgColor != null),
        assert(circularBorderRadius != null);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title != null ? Text(title) : null,
      content: message != null ? Text(message) : null,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(circularBorderRadius)),
      actions: <Widget>[
        negativeBtnText != null
            ? FlatButton(
          child: Text(negativeBtnText),
          textColor: CompanyColor.grey,
          onPressed: () {
            Navigator.of(context).pop();
            if (onNegativePressed != null) {
              onNegativePressed();
            }
          },
        )
            : null,
        positiveBtnText != null
            ? FlatButton(
          child: Text(positiveBtnText),
          textColor: CompanyColor.blueDark,
          onPressed: () {
            Navigator.of(context).pop();
            if (onPostivePressed != null) {
              onPostivePressed();
            }
          },
        )
            : null,
      ],
    );
  }
}

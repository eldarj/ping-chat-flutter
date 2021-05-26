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
        negativeBtnText != null ? TextButton(
          child: Text(negativeBtnText),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 15),
            primary: CompanyColor.grey,
            backgroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            if (onNegativePressed != null) {
              onNegativePressed();
            }
          },
        )
            : null,
        positiveBtnText != null ? Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          child: TextButton(
            child: Text(positiveBtnText),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 15),
              primary: CompanyColor.blueDark,
              backgroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (onPostivePressed != null) {
                onPostivePressed();
              }
            },
          ),
        )
            : null,
      ],
    );
  }
}

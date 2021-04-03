import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

class SnackBarsComponent {
  static SnackBar error({content, actionLabel, actionOnPressed, duration = const Duration(days: 100)}) {
    return SnackBar(
        duration: duration,
        backgroundColor: CompanyColor.red,
        content: Text(content != null ? content : 'Whoops! Something went wrong.'),
        action: SnackBarAction(textColor: Colors.white,
            label: actionOnPressed == null ? '' : actionLabel != null ? actionLabel : 'Try again',
            onPressed: actionOnPressed != null ? actionOnPressed : () {}));
  }

  static SnackBar success(content) {
    return SnackBar(
      duration: Duration(seconds: 2),
      backgroundColor: CompanyColor.green,
      content: Text(content),
    );
  }

  static SnackBar info(content) {
    return SnackBar(
      duration: Duration(seconds: 2),
      backgroundColor: CompanyColor.grey,
      content: Text(content),
    );
  }

  static SnackBar doubleBack() {
    return SnackBar(
        content: Text('Press Back twice to close the application', style: TextStyle(color: Colors.white)),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orangeAccent
    );
  }
}

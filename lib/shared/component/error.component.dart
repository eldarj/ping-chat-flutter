import 'package:flutter/material.dart';

class ErrorComponent {
  static Widget build({
    icon = Icons.error_outline,
    text = 'Something went wrong',
    actionLabel = 'Try again',
    actionOnPressed
  }) {
    return Center(
      child: Container(
        width: 230,
        margin: EdgeInsets.only(bottom: 30),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  child: Icon(icon, color: Colors.grey, size: 60)),
              Container(
                  margin: EdgeInsets.only(bottom: 20, top: 10),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  )),
              actionOnPressed != null ? FlatButton(color: Colors.red.shade400,
                  onPressed: actionOnPressed,
                  child: Text(actionLabel, style: TextStyle(color: Colors.white))
              ) : Container()
            ]),
      ),
    );
  }
}

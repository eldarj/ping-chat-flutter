import 'package:flutter/material.dart';

class ErrorComponent {

  static Widget build({
    displayErrorImage = false,
    icon = Icons.error_outline,
    text = 'Something went wrong',
    actionLabel = 'Try again',
    actionOnPressed,
  }) {
    return Center(
      child: Container(
        width: 230,
        margin: EdgeInsets.only(bottom: 30),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              displayErrorImage ? Opacity(
                  opacity: 0.8,
                  child: Image.asset('static/graphic/sticker/panda/panda7.png', width: 150, height: 150)) : Container(
                child: Icon(icon, color: Colors.grey, size: 60)
              ),
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

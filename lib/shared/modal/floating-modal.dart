import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class FloatingModal extends StatelessWidget {
  final Widget child;

  const FloatingModal({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 2),
        child: Container(
          child: child,
        ),
      ),
    );
  }
}

// TODO: Reorganize this
buildShareItem({color, icon, text, onTap, isLoading = false, spinnerColor}) {
  return Container(
    child: Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
              height: 75, width: 75,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [ BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 2.0, // soften the shadow
                  spreadRadius: 5.0, //extend the shadow
                )],
              ),
              child: Align(
                  child: isLoading ? Spinner(size: 25, color: spinnerColor) : Icon(icon, color: Colors.white)
              )),
        ),
        Container(
            padding: EdgeInsets.all(10),
            child: Text(text, style: TextStyle(color: Colors.black45, fontSize: 15)))
      ],
    ),
  );
}

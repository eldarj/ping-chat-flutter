import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class FloatingModal extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const FloatingModal({Key key, this.child, this.backgroundColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
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

Future<T> showFloatingModalBottomSheet<T>({
  @required BuildContext context,
  @required WidgetBuilder builder,
  Color backgroundColor,
}) async {
  final result = await showCustomModalBottomSheet(
      context: context,
      builder: builder,
      containerWidget: (_, animation, child) => FloatingModal(
        child: child,
      ),
      expand: false);

  return result;
}

buildShareItem({color, icon, text, onTap}) {
  return Container(
    child: Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
              height: 75, width: 75,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [ BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 1.0, // soften the shadow
                  spreadRadius: 5.0, //extend the shadow
                )],
              ),
              child: Icon(icon, color: Colors.white)),
        ),
        Container(
            padding: EdgeInsets.all(10),
            child: Text(text, style: TextStyle(color: Colors.black45, fontSize: 15)))
      ],
    ),
  );
}

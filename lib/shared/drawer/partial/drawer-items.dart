import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

Widget buildSectionTitle(String sectionTitle) {
  return Container(
      padding: EdgeInsets.only(top: 15, left: 20),
      child: Text("$sectionTitle", style: TextStyle(fontSize: 12, color: Colors.grey)));
}

Widget buildDrawerItem(BuildContext context, String labelName, Widget iconWidget,
    {
      Widget activity, Function onTapFunction, String labelDescription = '', crossAxisAlignment = CrossAxisAlignment.center,
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20)
    }) {
  return Material(
    color: Colors.white,
    child: InkWell(
      onTap: activity != null ? () {
        NavigatorUtil.push(context, activity);
      } : onTapFunction,
      child: Container(
        padding: padding,
        child: Row(
          crossAxisAlignment: crossAxisAlignment,
          children: <Widget>[
            Container(
                padding: EdgeInsets.only(right: 10),
                child: iconWidget),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(labelName, style: TextStyle(
                color: Colors.black,
              )),
              labelDescription != null && labelDescription != '' ? Text(labelDescription, style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey
              )) : Container()
            ])
          ],
        ),
      ),
    ),
  );
}

Widget buildIcon({ IconData icon, String iconPath, Color backgroundColor = Colors.lightBlueAccent}) {
  return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Container(width: 40, height: 40, padding: EdgeInsets.all(10),
          child: icon != null ? Icon(icon, size: 20, color: Colors.white)
              : Image.asset(iconPath, height: 20, color: Colors.white)));
}

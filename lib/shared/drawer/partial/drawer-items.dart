
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

Widget buildSectionTitle(String sectionTitle) {
  return Container(
      padding: EdgeInsets.only(top: 18, left: 20),
      child: Text("$sectionTitle", style: TextStyle(fontSize: 12, color: Colors.grey)));
}

Widget buildDrawerItem(BuildContext context, String labelName, Widget iconWidget,
    {
      Widget activity, Function onTapFunction, String labelDescription = ''
    }) {
  return InkWell(
    onTap: activity != null ? () {
      NavigatorUtil.push(context, activity);
    } : onTapFunction,
    child: Container(
      padding: EdgeInsets.only(top: 10, bottom: 10, left: 25),
      child: Row(
        children: <Widget>[
          Container(
              padding: EdgeInsets.only(right: 10),
              child: iconWidget),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(labelName, style: TextStyle(
              color: Colors.black,
            )),
            labelDescription != '' ? Text(labelDescription, style: TextStyle(
                fontSize: 12,
                color: Colors.grey
            )) : Container()
          ])
        ],
      ),
    ),
  );
}

Widget buildIcon({ IconData icon, String iconPath, Color backgroundColor = Colors.lightBlueAccent }) {
  return Container(
      padding: EdgeInsets.all(7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Container(width: 25, height: 25,
          child: icon != null ? Icon(icon, size: 25, color: Colors.white)
              : Image.asset(iconPath, height: 25, color: Colors.white)));
}

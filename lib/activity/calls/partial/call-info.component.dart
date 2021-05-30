
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

chatListCallInfo(callType) {
  var icon = Icons.call;
  var iconColor = Colors.grey.shade500;
  var text = '';

  if (callType == 'FAILED') {
    icon = Icons.call_made;
    iconColor = Colors.red;
    text = 'Call';
  } else if (callType == 'OUTGOING') {
    icon = Icons.call_made;
    iconColor = Colors.green;
    text = 'Call';
  }

  return Row(
      children: [
        Container(
          margin: EdgeInsets.only(right: 5),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        Text(text, style: TextStyle(color: Colors.grey.shade500))
      ]
  );
}

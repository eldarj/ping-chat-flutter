
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

chatListCallInfo(callType, isCaller) {
  var icon = Icons.call;
  var iconColor = Colors.grey.shade500;
  var text = 'Call';

  if (callType == 'FAILED') {
    if (isCaller) {
      icon = Icons.phone;
      iconColor = Colors.red;
      text = 'Call';
    } else {
      icon = Icons.phone_missed;
      iconColor = Colors.red;
      text = 'Missed call';
    }

  } else if (callType == 'OUTGOING') {
    if (isCaller) {
      icon = Icons.phone;
      iconColor = Colors.green;
      text = 'Call';
    } else {
      icon = Icons.phone_callback_rounded;
      iconColor = Colors.green;
      text = 'Received call';
    }

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

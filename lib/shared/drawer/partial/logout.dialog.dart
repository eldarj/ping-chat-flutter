

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/auth/logout.activity.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text('Odjavi se'),
        content: Text('Sigurno se želite odjaviti?'),
        actionsPadding: EdgeInsets.only(right: 10),
        actions: [
          FlatButton(
              child: Text('Da, odjavi me', style: TextStyle(fontWeight: FontWeight.w400, color: Theme.of(context).accentColor)),
              onPressed: () {
                NavigatorUtil.replace(context, LogoutActivity());
              }),
          GradientButton(text: 'Ne',
              bubble: GradientButtonBubble.fromBottomRight,
              onPressed: () {
                Navigator.of(context).pop();
              })
        ]
    );
  }
}

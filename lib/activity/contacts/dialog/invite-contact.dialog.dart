

import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:flutterping/util/http/http-client.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';

class InviteContactDialog extends StatefulWidget {
  final String contactPhoneNumber;
  final String contactName;

  InviteContactDialog({this.contactPhoneNumber, this.contactName}): super();

  @override
  State<StatefulWidget> createState() => InviteContactDialogState();
}

class InviteContactDialogState extends BaseState<InviteContactDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text('Uspješno ste dodali kontakt'),
        content: Text('Napravili ste novi kontakt, ali nažalost, ${widget.contactName} ne koristi Ping Chat!\n\n'
            'Želite poslati besplatnu SMS pozivnicu na ${widget.contactPhoneNumber}?'),
        actionsPadding: EdgeInsets.only(right: 10),
        actions: [
          FlatButton(
              child: Text('Ne', style: TextStyle(fontWeight: FontWeight.w400, color: Theme.of(context).accentColor)),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          GradientButton(
              child: displayLoader ? Container(height: 20, width: 20, child: Spinner()) : Text('Da'),
              bubble: GradientButtonBubbleDirection.fromBottomRight,
              onPressed: () {
                doSendAuthRequest().then(onSuccessAuthRequest, onError: onErrorAuthRequest);
              })
        ]
    );
  }

  Future<void> doSendAuthRequest() async {
    setState(() {
      displayLoader = true;
    });

    http.Response response = await HttpClient.post('/api/contacts/invite', body: widget.contactPhoneNumber);

    await Future.delayed(Duration(seconds: 1));
    if (response.statusCode != 200) {
      throw new Exception();
    }
  }

  onSuccessAuthRequest(_) {
    setState(() { displayLoader = false; });
    Navigator.of(context).pop(true);
  }

  onErrorAuthRequest(var error) {
    setState(() { displayLoader = false; });
    Navigator.of(context).pop();
  }
}

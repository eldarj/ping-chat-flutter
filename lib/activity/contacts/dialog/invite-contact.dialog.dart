import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:flutterping/service/http/http-client.service.dart';
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
        title: Text('Contact added'),
        content: RichText(
            text: TextSpan(
              text: 'You added a contact, but it unfortunately seems like ',
              style: TextStyle(color: Colors.black87),
              children: [
                TextSpan(text: widget.contactName,
                    style: TextStyle(color: CompanyColor.bluePrimary, fontWeight: FontWeight.bold)),
                TextSpan(text: ' isn\'t using Ping Chat!\n\nWould you like to send a free invitational SMS to '),
                TextSpan(text: widget.contactPhoneNumber,
                    style: TextStyle(color: CompanyColor.bluePrimary, fontWeight: FontWeight.bold)),
                TextSpan(text: '?')
              ],
            )),
        actionsPadding: EdgeInsets.only(right: 10),
        actions: [
          FlatButton(
              child: Text('Ne', style: TextStyle(fontWeight: FontWeight.w400, color: Theme.of(context).accentColor)),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          GradientButton(
              child: displayLoader ? Container(height: 20, width: 20, child: Spinner()) : Text('Da'),
              bubble: GradientButtonBubble.fromBottomRight,
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

    http.Response response = await HttpClientService.post('/api/contacts/invite', body: widget.contactPhoneNumber);

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

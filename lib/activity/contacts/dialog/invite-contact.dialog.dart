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
              text: 'New contact added, but it unfortunately seems like ',
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
        actions: [
          TextButton(
              child: Text('No'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 15),
                primary: CompanyColor.grey,
                backgroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          Container(
            child: TextButton(
              child: displayLoader ? Spinner(size: 20) : Text('Send SMS'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 15),
                primary: CompanyColor.blueDark,
                backgroundColor: Colors.white,
              ),
              onPressed: () {
                doSendInvite().then(onInviteSuccess, onError: onInviteError);
              },
            )
          )
        ]
    );
  }

  Future<void> doSendInvite() async {
    setState(() {
      displayLoader = true;
    });

    http.Response response = await HttpClientService.post('/api/contacts/invite', body: widget.contactPhoneNumber);

    await Future.delayed(Duration(seconds: 1));

    if (response.statusCode != 200) {
      throw new Exception();
    }
  }

  onInviteSuccess(_) {
    setState(() { displayLoader = false; });
    Navigator.of(context).pop(true);
  }

  onInviteError(var error) {
    setState(() { displayLoader = false; });
    Navigator.of(context).pop();
  }
}

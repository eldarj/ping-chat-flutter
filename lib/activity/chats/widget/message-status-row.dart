
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

class MessageStatusRow extends StatelessWidget {
  final String text;

  final MainAxisAlignment mainAlignment;

  final bool sent;
  final bool received;
  final bool seen;

  const MessageStatusRow({Key key, this.seen, this.sent, this.received, this.text, this.mainAlignment = MainAxisAlignment.start}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget statusIconWidget;

    if (seen) {
      statusIconWidget = Stack(children: [
        Icon(Icons.check, color: Colors.green, size: 15),
        Container(margin: EdgeInsets.only(left: 5), child: Icon(Icons.check, color: Colors.green, size: 15))
      ]);
    } else if (received) {
      statusIconWidget = Stack(children: [
        Icon(Icons.check, color: Colors.grey, size: 15),
        Container(margin: EdgeInsets.only(left: 5), child: Icon(Icons.check, color: Colors.grey, size: 15))
      ]);
    } else if (sent) {
      statusIconWidget = Icon(Icons.check, color: Colors.grey, size: 13);
    } else {
      statusIconWidget = Icon(Icons.hourglass_empty, color: Colors.grey, size: 13);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: mainAlignment,
      children: <Widget>[
        Text(text, style: TextStyle(color: CompanyColor.grey, fontSize: 13)),
        Container(
            height: 15,
            width: 20,
            margin: EdgeInsets.only(right: 2.5),
            alignment: Alignment.center,
            child: statusIconWidget
        ),
      ],
    );
  }
}

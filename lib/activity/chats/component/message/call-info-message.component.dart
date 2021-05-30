import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/component/message/partial/status-label.component.dart';
import 'package:flutterping/model/message-dto.model.dart';

class CallInfoMessageComponent extends StatefulWidget {
  final MessageDto message;

  const CallInfoMessageComponent(
      {
        Key key,
        this.message,
      }) : super(key: key);

  @override
  State<StatefulWidget> createState() => CallInfoMessageComponentState();
}

class CallInfoMessageComponentState extends State<CallInfoMessageComponent> {
  ScaffoldState scaffold;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    scaffold = Scaffold.of(context);

    String text = '';
    var icon = Icons.call;
    var iconColor = Colors.white;

    if (widget.message.callType == 'FAILED') {
      text = 'Call (${widget.message.callDuration})';
      icon = Icons.call_made;
    } else if (widget.message.callType == 'OUTGOING') {
      text = 'Call (${widget.message.callDuration})';
      icon = Icons.call_made;
    }

    Widget messageWidget = Text(text, style: TextStyle(color: Colors.white));

    return Container(
      padding: EdgeInsets.only(top: 5, bottom: 5),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: Color.fromRGBO(47, 72, 88, 0.8),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                child: Icon(icon, color: iconColor, size: 16)
              ),
              Container(
                  margin: EdgeInsets.only(left: 5, right: 5, bottom: 2.5),
                  child: messageWidget
              ),
              MessageTimestampLabel(widget.message.sentTimestamp, Colors.grey.shade400, edited: false),
            ],
          ),
        ),
      ),
    );
  }
}

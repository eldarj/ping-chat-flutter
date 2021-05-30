import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/component/message/partial/status-label.component.dart';
import 'package:flutterping/model/message-dto.model.dart';

class PinnedInfoMessageComponent extends StatefulWidget {
  final MessageDto message;

  final bool isPeerMessage;
  final bool isPinnedMessage;

  const PinnedInfoMessageComponent(
      {
        Key key,
        this.message,
        this.isPeerMessage = false,
        this.isPinnedMessage = true,
      }) : super(key: key);

  @override
  State<StatefulWidget> createState() => PinnedInfoMessageComponentState();
}

class PinnedInfoMessageComponentState extends State<PinnedInfoMessageComponent> {
  ScaffoldState scaffold;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    scaffold = Scaffold.of(context);

    String text = (widget.isPeerMessage ? widget.message.senderContactName : 'You')
        + (widget.isPinnedMessage ? ' pinned' : ' unpinned')
        + ' a message';

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
                  margin: EdgeInsets.only(right: 5, bottom: 2.5),
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

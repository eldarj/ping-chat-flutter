import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-deleted.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-image.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-gif.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-sticker.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-text.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message.decoration.dart';
import 'package:flutterping/activity/chats/component/message/partial/status-label.component.dart';
import 'package:flutterping/activity/chats/component/message/reply.component.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/messaging/message-edit.publisher.dart';
import 'package:flutterping/service/messaging/message-pin.publisher.dart';
import 'package:flutterping/service/messaging/message-reply.publisher.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/duration.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

class InfoMessageComponent extends StatefulWidget {
  final MessageDto message;

  final bool isPeerMessage;
  final bool isPinnedMessage;

  const InfoMessageComponent(
      {
        Key key,
        this.message,
        this.isPeerMessage = false,
        this.isPinnedMessage = true,
      }) : super(key: key);

  @override
  State<StatefulWidget> createState() => InfoMessageComponentState();
}

class InfoMessageComponentState extends State<InfoMessageComponent> {
  ScaffoldState scaffold;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    scaffold = Scaffold.of(context);

    String text = (widget.isPeerMessage ? widget.message.senderContactName : 'You ')
        + (widget.isPinnedMessage ? 'pinned' : 'unpinned')
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

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutterping/activity/calls/callscreen.activity.dart';
import 'package:flutterping/activity/chats/component/message/peer-message.component.dart';
import 'package:flutterping/activity/chats/component/settings/chat-settings-menu.dart';
import 'package:flutterping/activity/chats/component/message/message.component.dart';
import 'package:flutterping/activity/chats/component/message/message.component.dart';
import 'package:flutterping/activity/chats/component/share-files/share-files.modal.dart';
import 'package:flutterping/activity/chats/single-chat/partial/chat-input-row.component.dart';
import 'package:flutterping/activity/chats/component/stickers/sticker-bar.component.dart';
import 'package:flutterping/activity/contacts/single/single-contact.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/model/message-download-progress.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/model/presence-event.model.dart';
import 'package:flutterping/service/contact/contact.publisher.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/messaging/image-download.publisher.dart';
import 'package:flutterping/service/messaging/message-pin.publisher.dart';
import 'package:flutterping/service/messaging/message-sending.service.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';import 'package:flutterping/service/messaging/unread-message.publisher.dart';

import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/info/info.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/modal/floating-modal.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/exception/custom-exception.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tus_client/tus_client.dart';

class PinnedMessagesActivity extends StatefulWidget {
  final ClientDto peer;

  final ContactDto contact;

  final MessageTheme myMessageTheme;

  PinnedMessagesActivity(
      this.myMessageTheme,
      {
        Key key,
        this.peer,
        this.contact
      }) :  super(key: key);

  @override
  State<StatefulWidget> createState() => PinnedMessagesActivityState();
}

class PinnedMessagesActivityState extends BaseState<PinnedMessagesActivity> {
  static const String STREAMS_LISTENER_ID = "PinnedMessagesActivityListener";

  bool displayLoader = true;

  ClientDto user;

  List<MessageDto> messages = new List();

  String picturesPath;

  onInit() async {
    picturesPath = await new StorageIOService().getPicturesPath();
    user = await UserService.getUser();

    doGetPinnedMessages().then(onGetMessagesSuccess, onError: onGetMessagesError);

    messagePinPublisher.onPinUpdate(STREAMS_LISTENER_ID, (PinEvent pinEvent) {
      if (!pinEvent.pinned) {
        setState(() {
          messages.removeWhere((element) => element.id == pinEvent.messageId);
        });
      }
    });
  }

  @override
  initState() {
    super.initState();
    onInit();
  }

  @override
  void deactivate() {
    if (messagePinPublisher != null) {
      messagePinPublisher.removeListener(STREAMS_LISTENER_ID);
    }

    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar.getBackAppBar(getScaffoldContext, centerTitle: false, titleText: 'Pinned messages'),
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return Container(
            color: Colors.white,
            child: Column(children: [
              Flexible(
                child: buildMessagesList(),
              ),
            ]),
          );
        })
    );
  }

  Widget buildMessagesList() {
    Widget widget = Center(child: Spinner());

    if (!displayLoader) {
      if (messages != null && messages.length > 0) {
        widget = Container(
          color: CompanyColor.backgroundGrey,
          child: ListView.builder(
            itemCount: messages == null ? 0 : messages.length,
            itemBuilder: (context, index) {
              return buildSingleMessage(messages[index],
                  isFirstMessage: index == messages.length - 1,
                  isLastMessage: index == 0);
            },
          ),
        );
      } else {
        widget = InfoComponent.noDataStitch();
      }
    }

    return widget;
  }

  Widget buildSingleMessage(MessageDto message, {isLastMessage, isFirstMessage = false}) {
    bool isPeerMessage = user.id != message.sender.id;
    String widgetKey = message.text != null ? message.text : message.fileName;

    Widget messageWidget;

    if (isPeerMessage) {
      messageWidget = PeerMessageComponent(
        key: new Key(widgetKey),
        margin: EdgeInsets.only(left: 5, right: 5),
        message: message,
        picturesPath: picturesPath,
      );
    } else {
      messageWidget = MessageComponent(
        widget.myMessageTheme,
        key: new Key(widgetKey),
        margin: EdgeInsets.only(left: 5, right: 5),
        message: message,
        picturesPath: picturesPath,
      );
    }

    return IgnorePointer(
      ignoring: message.pinLoading,
      child: AnimatedOpacity(
        opacity: message.pinLoading ? 0.5 : 1,
        duration: Duration(milliseconds: 500),
        child: Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [Shadows.bottomShadow()]
          ),
          child: Column(
              children: [
                buildMessagePinDetails(message),
                messageWidget
              ]),
        ),
      ),
    );
  }

  buildMessagePinDetails(message) {
    return Container(
        margin: EdgeInsets.only(bottom: 5),
        padding: EdgeInsets.symmetric(vertical: 5,horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pinned on ${DateTimeUtil.convertTimestampToDate(message.pinnedTimestamp)}', style: TextStyle(
              color: Colors.grey.shade400,
            )),
            TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.grey.shade200),
                onPressed: message.pinLoading ? null : () {
                  doUpdatePinStatus(message).then(onPinSuccess, onError: onPinError);
                },
                child: Row(
                  children: [
                    message.pinLoading ? Spinner(size: 20) : Row(children: [
                      Text('Unpin', style: TextStyle(color: Colors.grey.shade600)),
                      Container(
                          margin: EdgeInsets.only(left: 5, top: 1),
                          child: Icon(Icons.push_pin_outlined, size: 14, color: Colors.grey.shade600)),
                    ]),
                  ],
                ))
          ],
        )
    );
  }

  Future doGetPinnedMessages() async {
    String url = '/api/messages/pinned'
        '?userId=' + user.id.toString() +
        '&contactUserId=' + widget.peer.id.toString();

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return response.decode();
  }

  onGetMessagesSuccess(result) async {
    scaffold.removeCurrentSnackBar();

    List<MessageDto> parsedMessages = result.map<MessageDto>((m) => MessageDto.fromJson(m)).toList();

    setState(() {
      this.messages = parsedMessages;
      displayLoader = false;
      isError = false;
    });
  }

  onGetMessagesError(error) {
    print(error);

    setState(() {
      displayLoader = false;
      isError = true;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () async {
      setState(() {
        displayLoader = true;
        isError = false;
      });

      doGetPinnedMessages().then(onGetMessagesSuccess, onError: onGetMessagesError);
    }));
  }

  // Pin message
  Future<MessageDto> doUpdatePinStatus(MessageDto message) async {
    setState(() {
      message.pinLoading = true;
    });

    String url = '/api/messages/${message.id}/pin';

    message.pinned = false;
    http.Response response = await HttpClientService.post(url, body: !message.pinned);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    await Future.delayed(Duration(seconds: 1));

    return message;
  }

  onPinSuccess(message) {
    messagePinPublisher.emitPinUpdate(message.id, false);
  }

  onPinError(error) {
    // print(error);
  }
}


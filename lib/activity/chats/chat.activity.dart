

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/widget/message-status-row.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';

class ChatActivity extends StatefulWidget {
  final ClientDto peer;
  final String peerContactName;

  final String myContactName;

  final String statusLabel;

  final int contactBindingId;

  const ChatActivity({Key key, this.myContactName, this.peer,
    this.peerContactName, this.statusLabel, this.contactBindingId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatActivityState();
}

class ChatActivityState extends BaseState<ChatActivity> {
  static const String STREAMS_LISTENER_IDENTIFIER = "ChatActivityListener";

  var displayLoader = true;

  final TextEditingController textEditingController = TextEditingController();
  final FocusNode textFieldFocusNode = FocusNode();

  bool textFieldHasFocus = false;

  ClientDto user;
  int anotherUserId = 0;

  List<MessageDto> messages = new List();
  bool isLoadingOnScroll = false;
  int pageNumber = 1;
  int pageSize = 50;

  onInit() async {
    user = await UserService.getUser();
    anotherUserId = widget.peer.id;

    doGetMessages().then(onGetMessagesSuccess, onError: onGetMessagesError);

    dynamic userToken = await UserService.getToken();

    wsClientService.receivingMessagesPub.addListener(STREAMS_LISTENER_IDENTIFIER, (message) {
      setState(() {
        messages.insert(0, message);
      });

      sendSeenStatus(new MessageSeenDto(id: message.id,
          senderPhoneNumber: message.sender.countryCode.dialCode + message.sender.phoneNumber));
    });

    wsClientService.incomingSentPub.addListener(STREAMS_LISTENER_IDENTIFIER, (message) {
      setState(() {
        for(var i = messages.length - 1; i >= 0; i--){
          if (messages[i].sentTimestamp == message.sentTimestamp) {
            setState(() {
              messages[i].id = message.id;
              messages[i].sent = true;
            });
          }
        }
      });
    });

    wsClientService.incomingReceivedPub.addListener(STREAMS_LISTENER_IDENTIFIER, (messageId) {
      setState(() {
        for(var i = messages.length - 1; i >= 0; i--){
          if (messages[i].id == messageId) {
            setState(() {
              messages[i].received = true;
            });
          }
        }
      });
    });

    wsClientService.incomingSeenPub.addListener(STREAMS_LISTENER_IDENTIFIER, (messageId) {
      setState(() {
        for(var i = messages.length - 1; i >= 0; i--){
          if (messages[i].id == messageId) {
            setState(() {
              messages[i].seen = true;
            });
          }
        }
      });
    });
  }

  @override
  initState() {
    super.initState();

    onInit();

    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        print('KEYBOARD VISIBLITY');
        textFieldHasFocus = visible;
      },
    );

    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus) {
        setState(() {
          print('has focus');
          textFieldHasFocus = true;
        });
      }
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    wsClientService.receivingMessagesPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.incomingSentPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.incomingReceivedPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.incomingSeenPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar.getBackAppBar(getScaffoldContext, centerTitle: false,
            titleWidget: Row(
              children: [
                RoundProfileImageComponent(url: widget.peer.profileImagePath,
                    height: 45, width: 45, borderRadius: 45, margin: 0),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.peerContactName, style: TextStyle(fontWeight: FontWeight.normal)),
                    Text(widget.statusLabel, style: TextStyle(fontSize: 12, color: Colors.grey))
                  ]),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (choice) {
                  if (choice == 'info') {

                  } else if (choice == 'media') {
                    // NavigatorUtil.push(context, AddContactActivity());
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                        value: 'info',
                        child: Row(children: [ Container(margin:EdgeInsets.only(right: 5),
                            child: Icon(Icons.info_outline)), Text('View contact') ])
                    ),
                    PopupMenuItem<String>(
                        value: 'media',
                        child: Row(children: [ Container(margin:EdgeInsets.only(right: 5),
                            child: Icon(Icons.sd_storage)), Text('Shared media') ])
                    )
                  ];
                },
              )
            ]
        ),
        drawer: NavigationDrawerComponent(),
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return Container(
            color: Colors.white,
            child: Column(children: [
              buildMessagesList(),
              buildInputRow()
            ]),
          );
        })
    );
  }

  Widget buildMessagesList() {
    Widget widget = Center(child: Spinner());

    if (!displayLoader) {
      if (messages != null && messages.length > 0) {
        widget = Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: messages == null ? 0 : messages.length,
            itemBuilder: (context, index) {
              return buildSingleMessage(messages[index]);
            },
          ),
        );
      } else {
        widget = Center(
          child: Container(
            margin: EdgeInsets.all(25),
            child: Text('Here begins history', style: TextStyle(color: Colors.grey)),
          ),
        );
      }
    }

    return widget;
  }

  Widget buildSingleMessage(MessageDto message) {
    bool isPeerMessage = user.id != message.sender.id;
    if (isPeerMessage) {
      return Row(
        children: <Widget>[
          Container(
            width: 200.0,
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(0),
                  bottomLeft: Radius.circular(0),
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 1, spreadRadius: 1)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      padding: EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 0),
                      child: Text(message.text)),
                  Container(
                      margin: EdgeInsets.only(right: 5, bottom: 2.5),
                      alignment: Alignment.bottomRight,
                      child: Text(DateTimeUtil.convertTimestampToChatFriendlyDate(message.sentTimestamp),
                        style: TextStyle(color: CompanyColor.grey, fontSize: 12),
                      )),
                ]),
          )
        ],
        mainAxisAlignment: MainAxisAlignment.start,
      );
    } else {
      return Row(
        children: <Widget>[
          Container(
            width: 200.0,
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(0),
            decoration: BoxDecoration(
                color: CompanyColor.myMessageBackground,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    topRight: Radius.circular(0),
                    bottomRight: Radius.circular(0)),
                border: Border.all(color: CompanyColor.myMessageBorder, width: 1),
                boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 1, spreadRadius: 1)]
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      padding: EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 0),
                      child: Text(message.text, style: TextStyle(fontSize: 15))),
                  MessageStatusRow(
                      text: DateTimeUtil.convertTimestampToChatFriendlyDate(message.sentTimestamp),
                      mainAlignment: MainAxisAlignment.end,
                      sent: message.sent, received: message.received, seen: message.seen),
                ]),
          )
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    }
  }

  Widget buildInputRow() {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [Shadows.topShadow()],
          borderRadius: BorderRadius.circular(20),
        ),
        width: MediaQuery.of(context).size.width,
        child: Row(children: [
          Container(
            child: IconButton(
              icon: Icon(Icons.tag_faces),
              onPressed: () {},
              color: CompanyColor.blueDark,
            ),
          ),
          Expanded(child: Container(
            child: TextField(
              onSubmitted: (value) {
                // onSendMessage(textEditingController.text, 0);
              },
              style: TextStyle(fontSize: 15.0),
              controller: textEditingController,
              decoration: InputDecoration.collapsed(
                hintText: 'Vaša poruka...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              focusNode: textFieldFocusNode,
            ),
          )),
          Container(
            child: Container(
              height: 30, width: 30,
              decoration: BoxDecoration(
                border: Border.all(color: CompanyColor.blueDark, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.gif, color: CompanyColor.blueDark),
            ),
          ),
          Container(
            child: IconButton(
              icon: Icon(Icons.image),
              onPressed: () {},
              color: CompanyColor.blueDark,
            ),
          ),
          Container(
            child: IconButton(
              icon: Icon(Icons.photo_camera),
              onPressed: () {},
              color: CompanyColor.blueDark,
            ),
          ),
          textFieldHasFocus ? IconButton(onPressed: doSendMessage, icon: Icon(Icons.send)) :
          Container(
              margin: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
              height: 45, width: 45,
              decoration: BoxDecoration(
                color: CompanyColor.blueDark,
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                icon: Icon(Icons.mic),
                iconSize: 18,
                onPressed: () {},
                color: Colors.white,
              )
          ),
        ]));
  }

  doSendMessage() {
    MessageDto message = new MessageDto();
    message.text = textEditingController.text;
    textEditingController.clear();

    message.sender = user;
    message.receiver = widget.peer;
    message.senderContactName = widget.myContactName;
    message.receiverContactName = widget.peerContactName;

    message.sent = false;
    message.received = false;
    message.seen = false;

    message.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    message.contactBindingId = widget.contactBindingId;

    setState(() {
      messages.insert(0, message);
    });

    sendMessage(message);
  }

  Future doGetMessages({page = 1, clearRides = false, favouritesOnly = false}) async {
    if (clearRides) {
      messages.clear();
      pageNumber = 1;
    }

    String url = '/api/messages'
        '?pageNumber=' + (page - 1).toString() +
        '&pageSize=' + pageSize.toString() +
        '&userId=' + user.id.toString() +
        '&anotherUserId=' + anotherUserId.toString();

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    dynamic result = response.decode();

    return {'messages': result['page'], 'totalElements': result['totalElements']};
  }

  onGetMessagesSuccess(result) {
    scaffold.removeCurrentSnackBar();

    List filteredMessages = result['messages'];

    filteredMessages.forEach((element) {
      messages.add(MessageDto.fromJson(element));
    });

    setState(() {
      displayLoader = false;
      isLoadingOnScroll = false;
      isError = false;
    });
  }

  onGetMessagesError(error) {
    print(error);
    setState(() {
      displayLoader = false;
      isLoadingOnScroll = false;
      isError = true;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () async {
      setState(() {
        displayLoader = true;
        isError = false;
      });

      doGetMessages(clearRides: true).then(onGetMessagesSuccess, onError: onGetMessagesError);
    }));
  }
}

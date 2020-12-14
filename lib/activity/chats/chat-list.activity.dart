import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/chat.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/service/global-app.service.dart';
import 'package:flutterping/service/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/linear-progress-loader.component.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:flutterping/util/http/http-client.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:flutterping/util/ws/ws-client.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/util/extension/http.response.extension.dart';

class ChatListActivity extends StatefulWidget {
  const ChatListActivity();

  @override
  State<StatefulWidget> createState() => new ChatListActivityState();
}

class ChatListActivityState extends BaseState<ChatListActivity> {
  var displayLoader = true;

  WsClient wsClient;

  int userId = 0;

  List<MessageDto> chats = new List();
  int totalChatsLoaded = 0;

  bool isLoadingOnScroll = false;
  bool noMoreChatsToLoad = false;
  int pageSize = 50;
  int pageNumber = 1;

  onInit() async {
    dynamic user = await UserService.getUser();
    dynamic userToken = await UserService.getToken();
    userId = user.id;

    // Register UI ws client listener
    wsClient = new WsClient(userToken, onConnectedFunc: () {
      wsClient.subscribe(destination: '/users/status', callback: (frame) async {
        print('USERS STATUS CHANGE');
        print(frame);
      });
    });

    globalAppService.listenToReceivingMessages('chatlist_receivingmessages', (message) {
      wsClient.send('/messages/received', new MessageSeenDto(id: message.id,
          senderPhoneNumber: message.sender.countryCode.dialCode + message.sender.phoneNumber));

      chats.forEach((ch) => {
        if (ch.contactBindingId == message.contactBindingId) {
          setState(() {
            ch.text = message.text;
          })
        }
      });
    });
    globalAppService.listenToReceivingMessages('chatlist_receivingmessages', (message) {
      wsClient.send('/messages/received', new MessageSeenDto(id: message.id,
          senderPhoneNumber: message.sender.countryCode.dialCode + message.sender.phoneNumber));
    });

    doGetChatData(page: pageNumber).then(onGetChatDataSuccess, onError: onGetChatDataError);
  }

  onDispose() async {
  }

  @override
  initState() {
    super.initState();
    onInit();
  }

  @override
  void dispose() {
    wsClient.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar.getProfileAppBar(scaffold, titleText: 'Chats'),
        drawer: NavigationDrawerComponent(),
        bottomNavigationBar: new BottomNavigationComponent(currentIndex: 0).build(context),
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return buildActivityContent();
        })
    );
  }

  Widget buildActivityContent() {
    Widget widget = ActivityLoader.build();

    if (!displayLoader) {
      if (!isError) {
        widget = Container(
          child: Column(
            children: [
              Opacity(
                  opacity: isLoadingOnScroll ? 1 : 0,
                  child: LinearProgressLoader.build(context)
              ),
              chats != null && chats.length > 0 ? buildListView() :
              Center(
                child: Container(
                  margin: EdgeInsets.all(25),
                  child: Text('Nemate poruka', style: TextStyle(color: Colors.grey)),
                ),
              )
            ],
          ),
        );
      } else {
        widget = ErrorComponent.build(actionOnPressed: () async {
          setState(() {
            displayLoader = true;
            isError = false;
          });

          doGetChatData(clearChats: true).then(onGetChatDataSuccess, onError: onGetChatDataError);
        });
      }
    }

    return widget;
  }

  Widget buildListView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!displayLoader && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          getNextPageOnScroll();
        }
      },
      child: Expanded(
        child: ListView.builder(
          itemCount: chats == null ? 0 : chats.length,
          itemBuilder: (context, index) {
            // TODO: Move this to onSuccess
            var chat = chats[index];
            var contact, profileUrl, contactName, isOnline, lastOnline, statusLabel;

            if (userId == chat.sender.id) {
              contact = chat.receiver;
              profileUrl = chat.receiver.profileImagePath;
              contactName = chat.receiverContactName;
              isOnline = chat.receiverOnline;
              if (!isOnline) {
                lastOnline = chat.receiverLastOnlineTimestamp;
              }
            } else {
              contact = chat.sender;
              profileUrl = chat.sender.profileImagePath;
              contactName = chat.senderContactName;
              isOnline = chat.senderOnline;
              lastOnline = chat.senderLastOnlineTimestamp;
            }

            return buildSingleConversationRow(
              contact: contact,
              profile: profileUrl,
              contactName: contactName??'fixme',
              contactBindingId: chat.contactBindingId,
              messageContent: chat.text,
              seen: chat.seen,
              isOnline: isOnline,
              statusLabel: isOnline ? 'Online' : DateTimeUtil.convertTimestampToTimeAgo(lastOnline),
              messageSent: DateTimeUtil.convertTimestampToTimeAgo(chat.sentTimestamp),
            );
          },
        ),
      ),
    );
  }


  Widget buildSingleConversationRow({ClientDto contact, String profile, String contactName, String messageContent,
    bool displaySeen = true, bool seen = true, String messageSent, bool isOnline = false, String statusLabel = '',
    int contactBindingId = 0
  }) {
    return GestureDetector(
      onTap: () {
        NavigatorUtil.push(context, ChatActivity(clientDto: contact, contactName: contactName,
            statusLabel: statusLabel, contactBindingId: contactBindingId));
      },
      child: Container(
        height: 75,
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))
        ),
        padding: EdgeInsets.all(10),
        child: Container(
          child: Row(
              children: [
                Container(
                    padding: EdgeInsets.only(right: 10),
                    child: Stack(
                        alignment: AlignmentDirectional.topEnd,
                        children: [
                          RoundProfileImageComponent(url: profile, margin: 2.5, borderRadius: 50, height: 50, width: 50),
                          Container(
                              decoration: BoxDecoration(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  border: Border.all(color: Colors.white, width: 1),
                                  borderRadius: BorderRadius.circular(50)
                              ),
                              margin: EdgeInsets.all(5),
                              width: 10, height: 10)
                        ])
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              alignment: Alignment.topLeft,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        child: Text(contactName, style: TextStyle(fontSize: 18,
                                            fontWeight: FontWeight.bold, color: Colors.black87))),
                                    Row(
                                      children: <Widget>[
                                        Text(messageContent, style: TextStyle(color: Colors.grey)),
                                        displaySeen ? Container(
                                            margin: EdgeInsets.only(left: 5),
                                            child: seen? Icon(Icons.check, color: Colors.green, size: 14)
                                                : Icon(Icons.check, color: Colors.grey, size: 14)
                                        ) : Container(),
                                      ],
                                    )
                                  ]
                              ),
                            )
                          ],
                        ),
                      ),
                      Text('$messageSent',
                          style: TextStyle(fontSize: 12, color: Colors.grey))
                    ],
                  ),
                )
              ]
          ),
        ),
      ),
    );
  }

  void getNextPageOnScroll() async {
    if (!isLoadingOnScroll && !noMoreChatsToLoad) {
      setState(() {
        isLoadingOnScroll = true;
      });
      pageNumber++;
      doGetChatData(page: pageNumber).then(onGetChatDataSuccess, onError: onGetChatDataError);
    }
  }

  Future<void> doGetChatData({page = 1, clearChats = false}) async {
    if (clearChats) {
      chats.clear();
      pageNumber = 1;
    }

    String url = '/api/chat/$userId'
        '?pageNumber=' + (page - 1).toString() +
        '&pageSize=' + pageSize.toString();

    http.Response response = await HttpClient.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    dynamic result = response.decode();

    return {'chats': result['page'], 'totalElements': result['totalElements']};
  }

  void onGetChatDataSuccess(result) async {
    List filteredChats = result['chats'];
    totalChatsLoaded += result['totalElements'];

    if (result['totalElements'] == 0) {
      noMoreChatsToLoad = true;
    }

    filteredChats.forEach((element) {
      chats.add(MessageDto.fromJson(element));
    });

    setState(() {
      displayLoader = false;
      isLoadingOnScroll = false;
      isError = false;
    });
  }

  void onGetChatDataError(Object error) {
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

      doGetChatData(clearChats: true).then(onGetChatDataSuccess, onError: onGetChatDataError);
    }));
  }
}

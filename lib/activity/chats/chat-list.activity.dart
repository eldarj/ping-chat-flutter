import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/chat.activity.dart';
import 'package:flutterping/activity/chats/widget/message-status-row.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/presence-event.model.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/linear-progress-loader.component.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/util/extension/http.response.extension.dart';

class ChatListActivity extends StatefulWidget {
  const ChatListActivity();

  @override
  State<StatefulWidget> createState() => new ChatListActivityState();
}

class ChatListActivityState extends BaseState<ChatListActivity> {
  static const String STREAMS_LISTENER_IDENTIFIER = "ChatListListener";

  var displayLoader = true;

  int userId = 0;

  List<MessageDto> chats = new List();
  int totalChatsLoaded = 0;

  bool isLoadingOnScroll = false;
  bool noMoreChatsToLoad = false;
  int pageSize = 50;
  int pageNumber = 1;

  Timer presenceTimer;

  initListenersAndGetData() async {
    dynamic user = await UserService.getUser();
    userId = user.id;

    wsClientService.userStatusPub.addListener(STREAMS_LISTENER_IDENTIFIER, (item) {
      print(item);
    });

    wsClientService.sendingMessagesPub.addListener(STREAMS_LISTENER_IDENTIFIER, (MessageDto message) {
      chats.forEach((chat) => {
        if (chat.contactBindingId == message.contactBindingId) {
          setState(() {
            chat.text = message.text;
            chat.sender = message.sender;
            chat.receiver = message.receiver;
            chat.senderContactName = message.senderContactName;
            chat.receiverContactName = message.receiverContactName;
            chat.sentTimestamp = message.sentTimestamp;
          })
        }
      });
    });

    wsClientService.receivingMessagesPub.addListener(STREAMS_LISTENER_IDENTIFIER, (message) {
      chats.forEach((chat) => {
        if (chat.contactBindingId == message.contactBindingId) {
          setState(() {
            chat.text = message.text;
            chat.sender = message.sender;
            chat.receiver = message.receiver;
            chat.senderContactName = message.senderContactName;
            chat.receiverContactName = message.receiverContactName;
            chat.sentTimestamp = message.sentTimestamp;
          })
        }
      });
    });

    wsClientService.incomingSentPub.addListener(STREAMS_LISTENER_IDENTIFIER, (message) async {
      setState(() {
        for(var i = chats.length - 1; i >= 0; i--){
          if (chats[i].sentTimestamp == message.sentTimestamp) {
            setState(() {
              chats[i].id = message.id;
              chats[i].sent = true;
            });
          }
        }
      });
    });

    wsClientService.incomingReceivedPub.addListener(STREAMS_LISTENER_IDENTIFIER, (messageId) async {
      setState(() {
        for(var i = chats.length - 1; i >= 0; i--){
          if (chats[i].id == messageId) {
            setState(() {
              chats[i].received = true;
            });
          }
        }
      });
    });

    wsClientService.incomingSeenPub.addListener(STREAMS_LISTENER_IDENTIFIER, (List<dynamic> seenMessagesIds) async {
      setState(() {
        // TODO: Change to map
        int lastSeenMessageId = seenMessagesIds.last;
        for(var i = chats.length - 1; i >= 0; i--){
          if (chats[i].id == lastSeenMessageId) {
            setState(() {
              chats[i].seen = true;
            });
          }
        }
      });
    });
    doGetChatData(page: pageNumber).then(onGetChatDataSuccess, onError: onGetChatDataError);
  }

  initPresenceFetcher() async {
    wsClientService.presencePub.addListener(STREAMS_LISTENER_IDENTIFIER, (PresenceEvent presenceEvent) {
      chats.forEach((chat) {
        if (presenceEvent.userPhoneNumber == chat.sender.fullPhoneNumber) {
          chat.senderOnline = presenceEvent.status;
          chat.senderLastOnlineTimestamp = presenceEvent.eventTimestamp;
          setState(() { });
        } else if (presenceEvent.userPhoneNumber == chat.receiver.fullPhoneNumber) {
          chat.receiverOnline = presenceEvent.status;
          chat.receiverLastOnlineTimestamp = presenceEvent.eventTimestamp;
          setState(() { });
        }
      });
    });

    presenceTimer = Timer.periodic(Duration(seconds: 30), (Timer t) async {
      print('RUN ME');
      List contactPhoneNumbers = chats.map((chat) {
        return userId == chat.sender.id ? chat.receiver.countryCode.dialCode + chat.receiver.phoneNumber
            : chat.sender.countryCode.dialCode + chat.sender.phoneNumber;
      }).toList();

      if (contactPhoneNumbers.length > 0) {
        http.Response response = await HttpClientService.getQuery(
            '/api/chat/presence', {'phoneNumbers': contactPhoneNumbers.join(',')});

        if (response.statusCode != 200) {
          throw new Exception();
        }

        List<dynamic> result = response.decode();

        String pox = 'asd';

        result.where((el) => el != null).forEach((element) {
          PresenceEvent presenceEvent = PresenceEvent.fromJson(element);
          // TODO: Replace with maps
          chats.forEach((chat) {
            if (userId == chat.sender.id) {
              chat.receiverOnline = presenceEvent.status;
              chat.receiverLastOnlineTimestamp = presenceEvent.eventTimestamp;
              setState(() { });
            } else if (userId == chat.receiver.id) {
              chat.senderOnline = presenceEvent.status;
              chat.senderLastOnlineTimestamp = presenceEvent.eventTimestamp;
              setState(() { });
            }
          });
        });
      }
    });
  }

  @override
  initState() {
    super.initState();
    initListenersAndGetData();
    initPresenceFetcher();
  }

  @override
  deactivate() {
    super.deactivate();

    presenceTimer.cancel();

    wsClientService.userStatusPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.sendingMessagesPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.receivingMessagesPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.incomingSentPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.incomingReceivedPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.incomingSeenPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.incomingSeenPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.presencePub.removeListener(STREAMS_LISTENER_IDENTIFIER);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar.getProfileAppBar(scaffold, titleText: 'Poruke'),
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
            var contact, profileUrl, peerContactName, myContactName, isOnline, lastOnline, statusLabel;

            if (userId == chat.sender.id) {
              contact = chat.receiver;
              profileUrl = chat.receiver.profileImagePath;
              myContactName = chat.senderContactName;
              peerContactName = chat.receiverContactName;
              isOnline = chat.receiverOnline;
              if (!isOnline) {
                lastOnline = chat.receiverLastOnlineTimestamp;
              }
            } else {
              contact = chat.sender;
              profileUrl = chat.sender.profileImagePath;
              myContactName = chat.receiverContactName;
              peerContactName = chat.senderContactName;
              isOnline = chat.senderOnline;
              lastOnline = chat.senderLastOnlineTimestamp;
            }

            return buildSingleConversationRow(
              contact: contact,
              profile: profileUrl,
              myContactName: myContactName,
              peerContactName: peerContactName??'fixme',
              contactBindingId: chat.contactBindingId,
              messageContent: chat.text,
              seen: chat.seen,
              isOnline: isOnline,
              statusLabel: isOnline ? 'Online' : 'Last seen ' + DateTimeUtil.convertTimestampToTimeAgo(lastOnline),
              messageSent: DateTimeUtil.convertTimestampToTimeAgo(chat.sentTimestamp),
              displaySeen: userId == chat.sender.id,
              message: chat,
            );
          },
        ),
      ),
    );
  }


  Widget buildSingleConversationRow({ClientDto contact, String profile, String peerContactName, String myContactName,
    String messageContent, bool displaySeen = true, bool seen = true, String messageSent, bool isOnline = false,
    String statusLabel = '', int contactBindingId = 0, MessageDto message
  }) {
    return GestureDetector(
      onTap: () {
        NavigatorUtil.push(context, ChatActivity(myContactName: myContactName, peer: contact, peerContactName: peerContactName,
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
                                        child: Text(peerContactName, style: TextStyle(fontSize: 18,
                                            fontWeight: FontWeight.bold, color: Colors.black87))),
                                    buildMessageContent(message)
                                  ]
                              ),
                            )
                          ],
                        ),
                      ),
                      MessageStatusRow(timestamp: message.sentTimestamp, displaySeen: displaySeen,
                          sent: message.sent, received: message.received, seen: message.seen),
                    ],
                  ),
                )
              ]
          ),
        ),
      ),
    );
  }

  buildMessageContent(message) {
    Widget widget;

    if (message.messageType == 'STICKER') {
      widget = Row(
        children: <Widget>[
          Image.asset('static/graphic/icon/sticker.png', color: Colors.grey.shade500, height: 25, width: 25),
          Text('Sticker', style: TextStyle(color: Colors.grey.shade500)),
        ],
      );
    } else if (message.messageType == 'TEXT_MESSAGE') {
      widget = Text(message.text??'fixme',
          overflow: TextOverflow.ellipsis, maxLines: 2,
          style: TextStyle(color: Colors.grey.shade500));
    } else if (message.messageType == 'IMAGE') {
      widget = Row(
        children: <Widget>[
          Container(
              margin: EdgeInsets.only(right: 5),
              child: Icon(Icons.photo_size_select_large, color: Colors.grey.shade500, size: 15)),
          Text('Image', style: TextStyle(color: Colors.grey.shade500)),
        ],
      );
    }

    return widget;
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

    http.Response response = await HttpClientService.get(url);

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

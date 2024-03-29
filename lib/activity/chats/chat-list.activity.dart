import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutterping/activity/calls/partial/call-info.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/status-label.component.dart';
import 'package:flutterping/activity/chats/single-chat/chat.activity.dart';
import 'package:flutterping/activity/contacts/search-contacts.activity.dart';
import 'package:flutterping/activity/policy/policy.activity.dart';
import 'package:flutterping/activity/profile/my-profile.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/model/presence-event.model.dart';
import 'package:flutterping/service/contact/contact.publisher.dart';
import 'package:flutterping/service/contact/contact.service.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/messaging/unread-message.publisher.dart';
import 'package:flutterping/service/notification/notification.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/profile/profile.publisher.dart';
import 'package:flutterping/service/voice/sip-client.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/info/info.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/linear-progress-loader.component.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:sip_ua/sip_ua.dart';
import 'package:volume/volume.dart';

class ChatListActivity extends StatefulWidget {
  const ChatListActivity();

  @override
  State<StatefulWidget> createState() => new ChatListActivityState();
}

class ChatListActivityState extends BaseState<ChatListActivity> {
  static const String STREAMS_LISTENER_ID = "ChatListListener";

  bool displayApp = false;

  bool isAppInForeground = true;

  bool displayLoader = true;

  int userId;
  String userProfileImagePath;

  List<MessageDto> chats = [];

  int totalChatsLoaded = 0;

  bool isLoadingOnScroll = false;
  bool noMoreChatsToLoad = false;
  int pageSize = 15;
  int pageNumber = 1;

  Timer presenceTimer;

  String registerStateString = 'None';

  StreamSubscription<FGBGType> foregroundSubscription;

  initialize() async {
    ClientDto user = await UserService.getUser();
    if (user != null && user.phoneNumber != null) {
      ContactService.syncContacts(user.countryCode.dialCode);

      instantiateWsClientService();
      initListenersAndGetData();
      initPresenceFetcher();

      setState(() {
        displayApp = true;
      });
    } else {
      NavigatorUtil.replace(context, PolicyActivity());
    }
  }

  initListenersAndGetData() async {
    ClientDto user = await UserService.getUser();
    userId = user.id;
    userProfileImagePath = user.profileImagePath;

    doGetChatData(page: pageNumber).then(onGetChatDataSuccess, onError: onGetChatDataError);

    // Initialize firebase notifications service
    await Firebase.initializeApp().then((_) {
      notificationService
          .initializeNotificationHandlers()
          .initializeLocalPlugin()
          .initializeRegister();
    });

    // Initialize message sound playing
    foregroundSubscription = FGBGEvents.stream.listen((event) {
      isAppInForeground = event == FGBGType.foreground;
    });

    // Initialize SIP UA Client
    sipClientService.register(user.fullPhoneNumber, '1234');

    sipClientService.addListener('123', (RegistrationState state) {
      setState(() {
        registerStateString = state.state.toString();
      });
    });

    wsClientService.sendingMessagesPub.addListener(STREAMS_LISTENER_ID, (MessageDto message) {
      chats.forEach((chat) => {
        if (chat.contactBindingId == message.contactBindingId) {
          setState(() {
            chat.text = message.text;
            chat.sender = message.sender;
            chat.receiver = message.receiver;
            chat.senderContactName = message.senderContactName;
            chat.receiverContactName = message.receiverContactName;
            chat.sentTimestamp = message.sentTimestamp;
            chat.messageType = message.messageType;
          })
        }
      });
    });

    wsClientService.receivingMessagesPub.addListener(STREAMS_LISTENER_ID, (message) async {
      sendReceivedStatus(new MessageSeenDto(id: message.id,
          senderPhoneNumber: message.sender.countryCode.dialCode + message.sender.phoneNumber));

      if (isAppInForeground) {
        int volume = await Volume.getVol;
        if (volume > 0) {
          playMessageSound();
        } else if (CURRENT_OPEN_CONTACT_BINDING_ID != message.contactBindingId) {
          Vibrate.vibrate();
        }
      }

      MessageDto chat = chats.firstWhere((element) => element.contactBindingId == message.contactBindingId,
          orElse: () => null);
      if (chat != null) {
        setState(() {
          chat.text = message.text;
          chat.sender = message.sender;
          chat.receiver = message.receiver;
          chat.senderContactName = message.senderContactName;
          chat.receiverContactName = message.receiverContactName;
          chat.sentTimestamp = message.sentTimestamp;
          chat.messageType = message.messageType;
          chat.deleted = message.deleted;
          chat.totalUnreadMessages = message.totalUnreadMessages;
        });
      } else {
        setState(() {
          chats.insert(0, message);
        });
      }
    });

    wsClientService.incomingSentPub.addListener(STREAMS_LISTENER_ID, (message) async {
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

    wsClientService.incomingReceivedPub.addListener(STREAMS_LISTENER_ID, (messageId) async {
      for(var i = chats.length - 1; i >= 0; i--){
        if (chats[i].id == messageId) {
          setState(() {
            chats[i].received = true;
          });
        }
      }
    });

    wsClientService.incomingSeenPub.addListener(STREAMS_LISTENER_ID, (List<dynamic> seenMessagesIds) async {
      int lastSeenMessageId = seenMessagesIds.last;
      for(var i = chats.length - 1; i >= 0; i--){
        if (chats[i].id == lastSeenMessageId) {
          setState(() {
            chats[i].seen = true;
          });
        }
      }
    });

    wsClientService.outgoingSeenPub.addListener(STREAMS_LISTENER_ID, (List<MessageSeenDto> seenMessages) async {
      var message = seenMessages[0];
      MessageDto chat = chats.firstWhere((element) => element.sender.fullPhoneNumber == message.senderPhoneNumber,
          orElse: () => null);
      if (chat != null) {
        setState(() {
          // chat.totalUnreadMessages = chat.totalUnreadMessages - 1;
          chat.totalUnreadMessages = 0;
        });
      }
    });

    // wsClientService.messageDeletedPub.addListener(STREAMS_LISTENER_ID, (MessageDto message) {
    //   for(var i = chats.length - 1; i >= 0; i--){
    //     if (chats[i].contactBindingId == message.contactBindingId) {
    //       setState(() {
    //         chats[i].deleted = true;
    //       });
    //     }
    //   }
    // });

    unreadMessagePublisher.addListener(STREAMS_LISTENER_ID, (contactBindingId) {
      chats.forEach((chat) => {
        if (chat.contactBindingId == contactBindingId) {
          setState(() {
            chat.totalUnreadMessages = 0;
          })
        }
      });
    });

    contactPublisher.onNameUpdate(STREAMS_LISTENER_ID, (ContactEvent contactEvent) {
      var chat = chats.firstWhere((element) => element.contactBindingId == contactEvent.contactBindingId, orElse: () => null);
      if (chat != null) {
        setState(() {
          if (chat.receiver.id == contactEvent.contactUserId) {
            chat.receiverContactName = contactEvent.value;
          } else {
            chat.senderContactName = contactEvent.value;
          }
        });
      }
    });

    contactPublisher.onContactDelete(STREAMS_LISTENER_ID, (ContactEvent contactEvent) {
      setState(() {
        chats.removeWhere((element) => element.contactBindingId == contactEvent.contactBindingId);
        totalChatsLoaded--;
      });
    });

    contactPublisher.onAllMessagesDelete(STREAMS_LISTENER_ID, (ContactEvent contactEvent) {
      setState(() {
        chats.removeWhere((element) => element.contactBindingId == contactEvent.contactBindingId);
        totalChatsLoaded--;
      });
    });

    profilePublisher.onProfileImageUpdate(STREAMS_LISTENER_ID, (String profileImage) {
      setState(() {
        user.profileImagePath = profileImage;
      });
    });
  }

  initPresenceFetcher() async {
    wsClientService.presencePub.addListener(STREAMS_LISTENER_ID, (PresenceEvent presenceEvent) {
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

        result.where((element) => element != null).forEach((element) {
          PresenceEvent presenceEvent = PresenceEvent.fromJson(element);
          // TODO: Replace with maps (due to Performance [?])
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

    initAudioStreamType();
  }

  initAudioStreamType() async {
    await Volume.controlVolume(AudioManager.STREAM_SYSTEM);
  }

  @override
  initState() {
    super.initState();
    initialize();
  }

  @override
  deactivate() {
    if (foregroundSubscription != null) {
      foregroundSubscription.cancel();
    }

    if (presenceTimer != null) {
      presenceTimer.cancel();
    }

    if (wsClientService != null) {
      wsClientService.sendingMessagesPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.receivingMessagesPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.incomingSentPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.incomingReceivedPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.incomingSeenPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.incomingSeenPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.presencePub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.messageDeletedPub.removeListener(STREAMS_LISTENER_ID);
    }

    if (unreadMessagePublisher != null) {
      unreadMessagePublisher.removeListener(STREAMS_LISTENER_ID);
    }

    if (contactPublisher != null) {
      contactPublisher.removeListener(STREAMS_LISTENER_ID);
    }

    if (profilePublisher != null) {
      profilePublisher.removeListener(STREAMS_LISTENER_ID);
    }

    if (sipClientService != null) {
      sipClientService.removeListener('123');
    }

    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return displayApp ? Scaffold(
        appBar: BaseAppBar.getProfileAppBar(scaffold, titleText: 'Chats',
            actions: [
              Container(
                width: 25, height: 25,
                margin: EdgeInsets.all(15),
                child: Material(
                  color: Colors.red,
                  clipBehavior: Clip.hardEdge,
                  borderRadius: BorderRadius.circular(100),
                  child: InkWell(
                    child: Container(
                        child: Icon(Icons.alternate_email, size: 16, color: Colors.white)
                    ),
                    onTap: () {
                      NavigatorUtil.push(context, MyProfileActivity(profileImageUrl: userProfileImagePath));
                    }
                  )
                ),
              ),
            ]
        ),
        drawer: NavigationDrawerComponent(),
        bottomNavigationBar: new BottomNavigationComponent(currentIndex: 0).build(context),
        floatingActionButton: FloatingActionButton(
          elevation: 1,
          backgroundColor: CompanyColor.blueDark,
          child: Icon(Icons.message, color: Colors.white),
          onPressed: () {
            NavigatorUtil.push(context, SearchContactsActivity());
          },
        ),
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          ROOT_CONTEXT = context;
          return buildActivityContent();
        })
    ) : Container();
  }

  Widget buildActivityContent() {
    Widget widget = ActivityLoader.contactsShimmer();

    if (!displayLoader) {
      if (!isError) {
        widget = Container(
          color: Colors.white,
          child: Column(
            children: [
              Opacity(
                  opacity: isLoadingOnScroll ? 1 : 0,
                  child: LinearProgressLoader.build(context)
              ),
              // buildStorySection(),
              chats != null && chats.length > 0 ? buildListView() : Container(
                margin: EdgeInsets.all(25),
                child: Text('You have no messages',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        );
      } else {
        widget = InfoComponent.errorPanda(
          onButtonPressed: () async {
            setState(() {
              displayLoader = true;
              isError = false;
            });

            doGetChatData(clearChats: true).then(onGetChatDataSuccess, onError: onGetChatDataError);
          }
        );
      }
    }

    return widget;
  }

  Widget buildStorySection() {
    return AnimatedContainer(
      height: 95,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200)
      ),
      duration: Duration(milliseconds: 100),
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Container(
                width: 55,
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: CompanyColor.blueLight, width: 5),
                  borderRadius: BorderRadius.circular(100),
                  color: CompanyColor.bluePrimary,
                ),
                child: Icon(Icons.add, color: Colors.white)
            ),
            RoundProfileImageComponent(),
            RoundProfileImageComponent(),
            RoundProfileImageComponent(),
            RoundProfileImageComponent(),
            RoundProfileImageComponent(),
            RoundProfileImageComponent(),
          ])
    );
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
          itemCount: chats == null ? 0 : chats.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                color: Colors.white,
                margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 0),
                child: Material(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(100),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () {
                      NavigatorUtil.push(context, SearchContactsActivity());
                    },
                    child: Container(
                        height: 40,
                        child: Row(
                          children: [
                            Container(
                                margin: EdgeInsets.only(left: 15, right: 10),
                                child: Icon(Icons.search, size: 17, color: Colors.grey.shade400)),
                            Text('Search', style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14
                            ))
                          ]
                        ))
                  ),
                ),
              );
            }

            index = index - 1;

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
              peerContactName: peerContactName ?? 'fixme',
              contactBindingId: chat.contactBindingId,
              messageContent: chat.text,
              seen: chat.seen,
              isOnline: isOnline,
              statusLabel: isOnline ? 'Online' : 'Last seen ' + DateTimeUtil.convertTimestampToTimeAgo(lastOnline),
              messageSent: DateTimeUtil.convertTimestampToTimeAgo(chat.sentTimestamp),
              isPeerMessage: userId == chat.receiver.id,
              message: chat,
            );
          },
        ),
      ),
    );
  }

  Widget buildSingleConversationRow({ClientDto contact, String profile, String peerContactName, String myContactName,
    String messageContent, bool isPeerMessage = false, bool seen = true, String messageSent, bool isOnline = false,
    String statusLabel = '', int contactBindingId = 0, MessageDto message
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          await Future.delayed(Duration(milliseconds: 250));
          NavigatorUtil.push(context, ChatActivity(
              myContactName: myContactName, peer: contact, peerContactName: peerContactName,
              statusLabel: statusLabel, contactBindingId: contactBindingId));
        },
        child: Container(
          padding: EdgeInsets.only(left: 10, right: 10, top: 7.5, bottom: 7.5),
          child: Container(
            child: Row(
                children: [
                  Container(
                      padding: EdgeInsets.only(right: 12.5),
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
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                alignment: Alignment.topLeft,
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                          child: Text(peerContactName, style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: message.totalUnreadMessages > 0 ? FontWeight.bold : FontWeight.normal,
                                              color: Colors.black87))),
                                      buildMessageContent(message, isPeerMessage)
                                    ]
                                ),
                              )
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            !isPeerMessage ? Container(
                                margin: EdgeInsets.only(bottom: 1),
                                padding: EdgeInsets.only(right: 2.5),
                                child: MessageStatusIcon(message.sent, message.received, message.seen)
                            ) : Container(),
                            MessageTimestampLabel(message.sentTimestamp, Colors.grey.shade500, edited: false),
                            message.totalUnreadMessages > 0 ? Container(
                                height: 20, width: 20,
                                alignment: Alignment.center,
                                margin: EdgeInsets.only(left: 5, bottom: 1.5),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CompanyColor.bluePrimary),
                                child: Text(message.totalUnreadMessages.toString(),
                                    style: TextStyle(fontSize: 12, color: Colors.white))
                            ) : Container(),
                          ],
                        ),
                      ],
                    ),
                  )
                ]
            ),
          ),
        ),
      ),
    );
  }

  buildMessageContent(message, isPeerMessage) {
    Widget widget;

    if (message.deleted) {
      widget = Text('Deleted', style: TextStyle(fontStyle: FontStyle.italic));
    } else if (message.messageType == 'MEDIA') {
      widget = Row(
        children: [
          Container(
              margin: EdgeInsets.only(right: 5),
              child: Icon(Icons.ondemand_video, color: Colors.grey.shade500, size: 15)),
          Text('Media', style: TextStyle(color: Colors.grey.shade500)),
        ],
      );
    } else if (message.messageType == 'RECORDING') {
      widget = Row(
        children: [
          Container(
              margin: EdgeInsets.only(right: 5),
              child: Icon(Icons.keyboard_voice, color: Colors.grey.shade500, size: 15)),
          Text('Recording', style: TextStyle(color: Colors.grey.shade500)),
        ],
      );
    } else if (message.messageType == 'FILE') {
      widget = Row(
        children: [
          Container(
              margin: EdgeInsets.only(right: 5),
              child: Icon(Icons.insert_drive_file, color: Colors.grey.shade500, size: 15)),
          Text('File', style: TextStyle(color: Colors.grey.shade500)),
        ],
      );
    } else if (message.messageType == 'IMAGE') {
      widget = Row(
        children: [
          Container(
              margin: EdgeInsets.only(right: 5),
              child: Icon(Icons.photo_size_select_large, color: Colors.grey.shade500, size: 15)),
          Text('Image', style: TextStyle(color: Colors.grey.shade500)),
        ],
      );
    } else if (message.messageType == 'STICKER') {
      widget = Row(
        children: [
          Container(
              margin: EdgeInsets.only(right: 5),
              child: Icon(Icons.sentiment_very_satisfied, color: Colors.grey.shade500, size: 15)),
          Text('Sticker', style: TextStyle(color: Colors.grey.shade500)),
        ],
      );
    } else if (message.messageType == 'GIF') {
      widget = Row(
        children: [
          Container(
              margin: EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey.shade500, width: 0.5)
              ),
              child: Icon(Icons.gif_outlined, color: Colors.grey.shade500, size: 15)),
          Text('GIF', style: TextStyle(color: Colors.grey.shade500)),
        ],
      );
    } else if (message.messageType == 'TEXT_MESSAGE') {
      widget = Text(message.text??'fixme',
          overflow: TextOverflow.ellipsis, maxLines: 2,
          style: TextStyle(color: Colors.grey.shade500));
    } else if (message.messageType == 'MAP_LOCATION') {
      widget = Row(
        children: [
          Container(
              margin: EdgeInsets.only(right: 5),
              child: Icon(Icons.location_on_outlined, color: Colors.grey.shade500, size: 15)),
          Text('Location', style: TextStyle(color: Colors.grey.shade500)),
        ],
      );
    } else if (message.messageType == 'PIN_INFO') {
      widget = Row(
        children: [
          Container(
            margin: EdgeInsets.only(right: 5),
            child: Icon(Icons.push_pin_outlined, color: Colors.grey.shade500, size: 14),
          ),
          Text('Pinned message', style: TextStyle(color: Colors.grey.shade500))
        ]
      );
    } else if (message.messageType == 'CALL_INFO') {
      widget = chatListCallInfo(message.callType, !isPeerMessage);
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

  Future doGetChatData({page = 1, clearChats = false}) async {
    if (clearChats) {
      chats.clear();
      pageNumber = 1;
    }

    String url = '/api/chat/$userId'
        '?pageNumber=' + (page - 1).toString() +
        '&pageSize=' + pageSize.toString();

    http.Response response = await HttpClientService.get(url);

    await Future.delayed(Duration(milliseconds: 500));

    if(response.statusCode != 200) {
      throw new Exception();
    }

    dynamic result = response.decode();

    return {
      'chats': result['page'],
      'totalElements': result['totalElements'],
    };
  }

  void onGetChatDataSuccess(result) async {
    List fetchedChats = result['chats'];
    totalChatsLoaded += result['totalElements'];

    if (result['totalElements'] == 0) {
      noMoreChatsToLoad = true;
    }

    fetchedChats.forEach((element) {
      MessageDto message = MessageDto.fromJson(element);

      chats.add(message);
    });

    scaffold.removeCurrentSnackBar();
    setState(() {
      displayLoader = false;
      isLoadingOnScroll = false;
      isError = false;
    });
  }

  void onGetChatDataError(Object error) async {
    print(error);
    setState(() {
      displayLoader = false;
      isLoadingOnScroll = false;
      isError = true;
    });
  }
}

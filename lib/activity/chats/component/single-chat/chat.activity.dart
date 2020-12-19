import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutterping/activity/chats/component/chat-settings-menu.dart';
import 'package:flutterping/activity/chats/component/message/message.component.dart';
import 'package:flutterping/activity/chats/component/message/message.component.dart';
import 'package:flutterping/activity/chats/component/share-files/share-files.modal.dart';
import 'package:flutterping/activity/chats/component/single-chat/partial/chat-input-row.component.dart';
import 'package:flutterping/activity/chats/component/stickers/sticker-bar.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/message-download-progress.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/model/presence-event.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/message-receiving.service.dart';
import 'package:flutterping/service/message-sending.service.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/modal/floating-modal.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:tus_client/tus_client.dart';

void downloadCallback(String id, DownloadTaskStatus status, int progress) {
  final SendPort send = IsolateNameServer.lookupPortByName('CHAT_ACTIVITY_DOWNLOADER_PORT_KEY');
  send.send([id, status]);
}

class ChatActivity extends StatefulWidget {
  final ClientDto peer;

  final String peerContactName;

  final String myContactName;

  final int contactBindingId;

  final MessageSendingService messageSendingService;

  String statusLabel;

  ChatActivity({Key key, this.myContactName, this.peer,
    this.peerContactName, this.statusLabel, this.contactBindingId})
      : messageSendingService = new MessageSendingService(peer, peerContactName, myContactName, contactBindingId), super(key: key);

  @override
  State<StatefulWidget> createState() => ChatActivityState();
}

class ChatActivityState extends BaseState<ChatActivity> {
  static const String CHAT_ACTIVITY_DOWNLOADER_PORT_ID = "CHAT_ACTIVITY_DOWNLOADER_PORT_KEY";
  static const String STREAMS_LISTENER_ID = "ChatActivityListener";

  final TextEditingController textController = TextEditingController();
  final FocusNode textFocusNode = new FocusNode();

  bool displayLoader = true;
  bool displaySendButton = false;
  bool displayScrollLoader = false;
  bool displayStickers = false;

  int userId;

  List<MessageDto> messages = new List();
  int totalMessages = 0;
  int pageNumber = 1;
  int pageSize = 50;

  bool previousWasPeerMessage;
  DateTime previousMessageDate;

  Function userPresenceSubscriptionFn;

  String picturesPath;

  onInit() async {
    picturesPath = await new StorageIOService().getPicturesPath();

    var user = await UserService.getUser();
    userId = user.id;

    PresenceEvent presenceEvent = new PresenceEvent();
    presenceEvent.userPhoneNumber = user.fullPhoneNumber;
    presenceEvent.status = true;

    sendPresenceEvent(presenceEvent);

    doGetMessages().then(onGetMessagesSuccess, onError: onGetMessagesError);
    userPresenceSubscriptionFn = wsClientService.subscribe('/users/${widget.peer.fullPhoneNumber}/status', (frame) async {
      PresenceEvent presenceEvent = PresenceEvent.fromJson(json.decode(frame.body));

      setState(() {
        widget.statusLabel = presenceEvent.status ? 'Online' : 'Last seen ' +
            DateTimeUtil.convertTimestampToTimeAgo(presenceEvent.eventTimestamp);
        wsClientService.presencePub.subject.add(presenceEvent);
      });
    });

    wsClientService.receivingMessagesPub.addListener(STREAMS_LISTENER_ID, (MessageDto message) async {
      if (message.messageType == 'IMAGE') {
        message.isDownloadingImage = true;
        message.downloadTaskId = await doDownloadAndStoreImage(message);
      }

      setState(() {
        messages.insert(0, message);
      });

      sendSeenStatus([new MessageSeenDto(id: message.id,
          senderPhoneNumber: message.sender.countryCode.dialCode + message.sender.phoneNumber)]);
    });

    wsClientService.sendingMessagesPub.addListener(STREAMS_LISTENER_ID, (message) async {
      setState(() {
        messages.insert(0, message);
      });

      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        message.displayCheckMark = false;
      });
    });

    wsClientService.incomingSentPub.addListener(STREAMS_LISTENER_ID, (message) async {
      for(var i = messages.length - 1; i >= 0; i--){
        if (messages[i].sentTimestamp == message.sentTimestamp) { // TODO: Check why sentTimestamp
          setState(() {
            messages[i].id = message.id;
            messages[i].sent = true;
          });
        }
      }
    });

    wsClientService.incomingReceivedPub.addListener(STREAMS_LISTENER_ID, (messageId) async {
      for(var i = messages.length - 1; i >= 0; i--){
        if (messages[i].id == messageId) {
          setState(() {
            messages[i].received = true;
          });
        }
      }
    });

    wsClientService.incomingSeenPub.addListener(STREAMS_LISTENER_ID, (List<dynamic> seenMessagesIds) async {
      // TODO: Change to map
      await Future.delayed(Duration(milliseconds: 500));
      for (var k = seenMessagesIds.length - 1; k >= 0; k--) {
        for(var i = messages.length - 1; i >= 0; i--){
          if (messages[i].id == seenMessagesIds[k]) {
            setState(() {
              messages[i].seen = true;
            });
          }
        }
      }
    });

    wsClientService.messageDeletedPub.addListener(STREAMS_LISTENER_ID, (MessageDto message) {
      for(var i = messages.length - 1; i >= 0; i--){
        if (messages[i].id == message.id) {
          setState(() {
            messages[i].deleted = true;
          });
        }
      }
    });
  }

  @override
  initState() {
    super.initState();

    onInit();

    ReceivePort _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port.sendPort, CHAT_ACTIVITY_DOWNLOADER_PORT_ID);
    _port.listen((dynamic data) {
      String downloadTaskId = data[0];
      DownloadTaskStatus status = data[1];

      if (status == DownloadTaskStatus.complete) {
        messages.where((message) => message.downloadTaskId == downloadTaskId).forEach((message) async {
          await Future.delayed(Duration(seconds: 1));
          setState(() {
            message.isDownloadingImage = false;
          });
        });
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);

    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
      },
    );

    textFocusNode.addListener(() {
      print('---------------------------------------------------');
      print(textFocusNode.hasFocus.toString());
      print('---------------------------------------------------');
      if (textFocusNode.hasFocus) {
        setState(() {
          displayStickers = false;
          displaySendButton = true;
        });
      } else {
        setState(() {
          displaySendButton = false;
        });
      }
    });
  }

  @override
  void deactivate() {
    super.deactivate();

    userPresenceSubscriptionFn();

    wsClientService.sendingMessagesPub.removeListener(STREAMS_LISTENER_ID);
    wsClientService.receivingMessagesPub.removeListener(STREAMS_LISTENER_ID);
    wsClientService.incomingSentPub.removeListener(STREAMS_LISTENER_ID);
    wsClientService.incomingReceivedPub.removeListener(STREAMS_LISTENER_ID);
    wsClientService.incomingSeenPub.removeListener(STREAMS_LISTENER_ID);
    wsClientService.messageDeletedPub.removeListener(STREAMS_LISTENER_ID);

    IsolateNameServer.removePortNameMapping(CHAT_ACTIVITY_DOWNLOADER_PORT_ID);
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
            actions: [ChatSettingsMenu()]
        ),
        drawer: NavigationDrawerComponent(),
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return Container(
            color: Colors.white,
            child: Column(children: [
              Flexible(
                child: Stack(alignment: Alignment.topCenter, children: [
                  buildMessagesList(),
                  displayScrollLoader ? SizedOverflowBox(
                      size: Size(100, 0),
                      child: Container(
                          padding: EdgeInsets.only(top: 50),
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(50)
                              ),
                              padding: EdgeInsets.all(10),
                              child: Spinner(size: 20)))) : Container(),
                ]),
              ),
              SingleChatInputRow(textController, textFocusNode, displayStickers, displaySendButton,
                  doSendMessage, onOpenShareBottomSheet, onOpenStickerBar),
              displayStickers ? StickerBar(
                sendFunc: doSendEmoji,
                peer: widget.peer,
                myContactName: widget.myContactName,
                peerContactName: widget.peerContactName,
                contactBindingId: widget.contactBindingId,
              ) : Container(),
            ]),
          );
        })
    );
  }

  Widget buildMessagesList() {
    Widget widget = Center(child: Spinner());

    if (!displayLoader) {
      if (messages != null && messages.length > 0) {
        widget = NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (!displayScrollLoader) {
              if (scrollInfo is UserScrollNotification) {
                UserScrollNotification userScrollNotification = scrollInfo as UserScrollNotification;
                if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent
                    && userScrollNotification.direction == ScrollDirection.reverse) {
                  doGetPageOnScroll();
                }
              }
            }
            return true;
          },
          child: Container(
            child: Container(
              color: Colors.transparent,
              child: ListView.builder(
                reverse: true,
                itemCount: messages == null ? 0 : messages.length,
                itemBuilder: (context, index) {
                  return buildSingleMessage(messages[index],
                      isFirstMessage: index == messages.length - 1,
                      isLastMessage: index == 0);
                },
              ),
            ),
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

  Widget buildSingleMessage(MessageDto message, {isLastMessage, isFirstMessage = false}) {
    bool displayTimestamp = true;
    bool isPeerMessage = userId != message.sender.id;
    DateTime thisMessageDate = DateTime.fromMillisecondsSinceEpoch(message.sentTimestamp);

    if (previousMessageDate != null && thisMessageDate.minute == previousMessageDate.minute
        && previousWasPeerMessage != null && previousWasPeerMessage == isPeerMessage
        && !isLastMessage) {
      displayTimestamp = false;
    }

    previousWasPeerMessage = isPeerMessage;
    previousMessageDate = thisMessageDate;

    return MessageComponent(
      margin: EdgeInsets.only(top: isFirstMessage ? 20 : 0, bottom: isLastMessage ? 20 : 0),
      message: message,
      isPeerMessage: isPeerMessage,
      displayTimestamp: displayTimestamp,
      picturesPath: picturesPath,
    );
  }

  onOpenStickerBar() {
    setState(() {
      displayStickers = !displayStickers;
      if (displayStickers) {
        FocusScope.of(context).requestFocus(new FocusNode());
      }
    });
  }

  onOpenShareBottomSheet() async {
    FocusScope.of(context).requestFocus(new FocusNode());
    await Future.delayed(Duration(milliseconds: 250));
    await showCustomModalBottomSheet(
        context: context,
        builder: (context) => ShareFilesModal(messageSendingService: widget.messageSendingService,
            onProgress: (message, progress) {
              setState(() {
                message.uploadProgress = progress / 100;
              });
            }
        ),
        containerWidget: (_, animation, child) => FloatingModal(child: child),
        expand: false
    );
  }

  doSendEmoji(stickerCode) async {
    widget.messageSendingService.sendSticker(stickerCode);
  }

  doSendMessage() {
    print('send my message');
    if (textController.text.length > 0) {
      widget.messageSendingService.sendTextMessage(textController.text);
      setState(() {
        textController.clear();
      });
    }
  }

  doGetPageOnScroll() async {
    if (!displayScrollLoader) {
      setState(() {
        displayScrollLoader = true;
      });

      await Future.delayed(Duration(seconds: 1));

      if (totalMessages != 0 && pageNumber * pageSize < totalMessages) {
        pageNumber++;
        doGetMessages(page: pageNumber).then(onGetMessagesSuccess, onError: onGetMessagesError);
      } else {
        setState(() {
          displayScrollLoader = false;
        });
      }
    }
  }

  doDownloadAndStoreImage(MessageDto message) async {
    try {
      return await FlutterDownloader.enqueue(
        url: message.fileUrl,
        savedDir: picturesPath,
        fileName: message.id.toString() + message.fileName,
        showNotification: false,
        openFileFromNotification: false,
      );
    } catch(exception) {
      print('Error downloading image on init.');
      print(exception);
    }
  }

  Future doGetMessages({page = 1, clearRides = false, favouritesOnly = false}) async {
    if (clearRides) {
      messages.clear();
      pageNumber = 1;
    }

    String url = '/api/messages'
        '?pageNumber=' + (page - 1).toString() +
        '&pageSize=' + pageSize.toString() +
        '&userId=' + userId.toString() +
        '&anotherUserId=' + widget.peer.id.toString();

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    dynamic result = response.decode();

    return {'messages': result['page'], 'totalElements': result['totalElements']};
  }

  onGetMessagesSuccess(result) async {
    print('-- ON GET MESSAGES SUCCESS --');
    scaffold.removeCurrentSnackBar();

    List fetchedMessages = result['messages'];
    totalMessages = result['totalElements'];

    MessageDto prevMessage;
    List<MessageSeenDto> unseenMessages = new List();
    var preparedMessages = fetchedMessages.map((e) async {
      var m = MessageDto.fromJson(e);

      // Download new images (TODO: Adjust downloading and displayin images)
      if (m.messageType == 'IMAGE' && !m.deleted) {
        bool imageExists = File(picturesPath + '/' + m.id.toString() + m.fileName).existsSync();
        if (userId == m.receiver.id && !imageExists) {
          m.isDownloadingImage = true;
          m.downloadTaskId = await doDownloadAndStoreImage(m);
        }
      }

      // Set prevmessage and chaining (ui bubbling)
      if (prevMessage == null) {
        m.chained = false;
        prevMessage = m;
      } else {
        prevMessage.chained = prevMessage.sender.id == m.sender.id;
        prevMessage = m;
      }

      // Collect unseen messages to update status on API
      if (!m.seen && userId != m.sender.id) {
        unseenMessages.add(new MessageSeenDto(id: m.id,
            senderPhoneNumber: m.sender.countryCode.dialCode + m.sender.phoneNumber));
      }
      return m;
    }).toList();

    messages.addAll(await Future.wait(preparedMessages));

    if (unseenMessages.length > 0) {
      sendSeenStatus(unseenMessages);
    }

    setState(() {
      displayLoader = false;
      displayScrollLoader = false;
      isError = false;
    });
  }

  onGetMessagesError(error) {
    print(error);
    setState(() {
      displayLoader = false;
      displayScrollLoader = false;
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


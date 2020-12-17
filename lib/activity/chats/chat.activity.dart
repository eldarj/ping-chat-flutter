import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutterping/activity/chats/widget/dummyupload/dummy-upload.dart';
import 'package:flutterping/activity/chats/widget/message/image-message.component.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/shared/modal/floating-modal.dart';
import 'package:flutterping/activity/chats/widget/share/share-files.modal.dart';


import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/widget/chat-settings-menu.dart';
import 'package:flutterping/activity/chats/widget/stickers/sticker-bar.dart';
import 'package:flutterping/activity/chats/widget/message/message.component.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/model/presence-event.model.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:tus_client/tus_client.dart';

class ChatActivity extends StatefulWidget {
  final ClientDto peer;

  final String peerContactName;

  final String myContactName;

  String statusLabel;

  final int contactBindingId;

  ChatActivity({Key key, this.myContactName, this.peer,
    this.peerContactName, this.statusLabel, this.contactBindingId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatActivityState();
}

class ChatActivityState extends BaseState<ChatActivity> {
  static const String STREAMS_LISTENER_IDENTIFIER = "ChatActivityListener";

  final TextEditingController textController = TextEditingController();
  final FocusNode textFocusNode = new FocusNode();

  bool displayLoader = true;
  bool displaySendButton = false;
  bool displayScrollLoader = false;

  bool displayStickers = false;

  int userId;
  int anotherUserId = 0;

  List<MessageDto> messages = new List();
  int totalMessages = 0;
  int pageNumber = 1;
  int pageSize = 50;

  bool previousWasPeerMessage;
  DateTime previousMessageDate;

  Function userPresenceSubscriptionFn;

  String picturesPath;

  onInit() async {
    var user = await UserService.getUser();
    userId = user.id;
    anotherUserId = widget.peer.id;

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

    wsClientService.receivingMessagesPub.addListener(STREAMS_LISTENER_IDENTIFIER, (message) {
      setState(() {
        messages.insert(0, message);
      });

      sendSeenStatus([new MessageSeenDto(id: message.id,
          senderPhoneNumber: message.sender.countryCode.dialCode + message.sender.phoneNumber)]);
    });

    wsClientService.incomingSentPub.addListener(STREAMS_LISTENER_IDENTIFIER, (message) async {
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

    wsClientService.incomingReceivedPub.addListener(STREAMS_LISTENER_IDENTIFIER, (messageId) async {
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

    wsClientService.incomingSeenPub.addListener(STREAMS_LISTENER_IDENTIFIER, (List<dynamic> seenMessagesIds) async {
      // TODO: Change to map
      await Future.delayed(Duration(milliseconds: 500));
      setState(() {
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
    });

    wsClientService.updateMessagePub.addListener(STREAMS_LISTENER_IDENTIFIER, (MessageDto message) async {
      messages.where((element) => element.id == message.id).forEach((element) {
        setState(() {element = message;});
      });
    });

    picturesPath = await new StorageIOService().getPicturesPath();
  }

  @override
  initState() {
    super.initState();

    onInit();

    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
      },
    );

    textFocusNode.addListener(() {
      if (textFocusNode.hasFocus) {
        setState(() {
          displayStickers = false;
          displaySendButton = true;
        });
      } else {
        displaySendButton = false;
      }
    });
  }

  @override
  void deactivate() {
    super.deactivate();

    userPresenceSubscriptionFn();

    wsClientService.receivingMessagesPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.incomingSentPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.incomingReceivedPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.incomingSeenPub.removeListener(STREAMS_LISTENER_IDENTIFIER);
    wsClientService.updateMessagePub.removeListener(STREAMS_LISTENER_IDENTIFIER);
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
              buildInputRow(),
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
                  getNextPageOfMessagesOnScroll();
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
    double width = MediaQuery.of(context).size.width - 150;

    bool isPeerMessage = userId != message.sender.id;

    bool displayTimestamp = true;
    final thisMessageDate = DateTime.fromMillisecondsSinceEpoch(message.sentTimestamp);

    if (previousMessageDate != null && thisMessageDate.minute == previousMessageDate.minute
        && previousWasPeerMessage != null && previousWasPeerMessage == isPeerMessage
        && !isLastMessage) {
      displayTimestamp = false;
    }

    previousWasPeerMessage = isPeerMessage;
    previousMessageDate = thisMessageDate;

    Widget messageWidget;

    if (message.messageType == 'IMAGE') {
      messageWidget = Container(
        margin: EdgeInsets.only(top: isFirstMessage ? 20 : 0, bottom: isLastMessage ? 20 : 0),
        child: ImageMessageComponent(
          message: message,
          picturesPath: picturesPath,
          isPeerMessage: isPeerMessage,
          displayTimestamp: displayTimestamp,
        ),
      );
    } else {
      messageWidget = Container(
        margin: EdgeInsets.only(top: isFirstMessage ? 20 : 0, bottom: isLastMessage ? 20 : 0),
        child: MessageComponent(
          isPeerMessage: isPeerMessage,
          content: message.text,
          maxWidth: width,
          displayTimestamp: displayTimestamp, sentTimestamp: message.sentTimestamp,
          sent: message.sent, received: message.received, seen: message.seen, displayCheckMark: message.displayCheckMark,
          chained: message.chained,
          messageType: message.messageType,
        ),
      );
    }

    return messageWidget;
  }

  Widget buildInputRow() {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [Shadows.topShadow()],
        ),
        width: MediaQuery.of(context).size.width,
        child: Row(children: [
          Container(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    displayStickers = !displayStickers;
                    if (displayStickers) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    }
                  });
                },
                child: Container(
                    height: 35, width: 50,
                    child: Image.asset('static/graphic/icon/sticker.png', color: CompanyColor.blueDark))
            ),
          ),
          Expanded(child: Container(
            child: TextField(
              textInputAction: TextInputAction.newline,
              onSubmitted: (value) {
                textController.text += "asd";
              },
              style: TextStyle(fontSize: 15.0),
              controller: textController,
              focusNode: textFocusNode,
              decoration: InputDecoration.collapsed(
                hintText: 'Vaša poruka...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          )),
          Container(
            child: IconButton(
              icon: Icon(Icons.attachment),
              onPressed: buildShareBottomSheet,
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
          displaySendButton ? IconButton(onPressed: doSendMessage, icon: Icon(Icons.send)) :
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

  buildShareBottomSheet() {
    MessageDto message = new MessageDto();
    message.messageType = 'IMAGE';
    message.uploadProgress = 0.0;
    message.isUploading = true;

    showFloatingModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareFilesModal(
        onPicked: (TusClient uploadClient, fileName, filePath, fileUrl) {
          message.fileName = fileName;
          message.filePath = filePath;
          message.fileUrl = fileUrl.toString();
          message.stopUploadFunc = () async {
            setState(() {
              message.deleted = true;
              message.isUploading = false;
            });
            await Future.delayed(Duration(seconds: 2));
            uploadClient.delete();

            // hit delete message api endpoint
          };
          _send(message);
        },
        onProgress: (progress) {
          var _uploadProgress = progress / 100;
          print('==== PROGRESS ' + _uploadProgress.toString());
          setState(() {
            message.uploadProgress = _uploadProgress;
          });
        },
        onComplete: (response) {
          message.isUploading = false;
        },
      ),
    );
  }

  doSendEmoji(stickerCode) {
    MessageDto message = new MessageDto();
    message.text = stickerCode;
    message.messageType = 'STICKER';
    _send(message);
  }

  doSendMessage() {
    if (textController.text.length > 0) {
      MessageDto message = new MessageDto();
      message.text = textController.text;
      message.messageType = 'TEXT_MESSAGE';
      textController.clear();
      _send(message);
    }
  }

  _send(message) async {

    message.receiver = widget.peer;
    message.senderContactName = widget.myContactName;
    message.receiverContactName = widget.peerContactName;

    message.sent = false;
    message.received = false;
    message.seen = false;
    message.displayCheckMark = true;
    message.chained = messages.first.sender == message.sender;

    message.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    message.contactBindingId = widget.contactBindingId;

    setState(() {
      messages.insert(0, message);
    });

    sendMessage(message);

    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      message.displayCheckMark = false;
    });
  }

  void getNextPageOfMessagesOnScroll() async {
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

  Future doGetMessages({page = 1, clearRides = false, favouritesOnly = false}) async {
    if (clearRides) {
      messages.clear();
      pageNumber = 1;
    }

    String url = '/api/messages'
        '?pageNumber=' + (page - 1).toString() +
        '&pageSize=' + pageSize.toString() +
        '&userId=' + userId.toString() +
        '&anotherUserId=' + anotherUserId.toString();

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    dynamic result = response.decode();

    return {'messages': result['page'], 'totalElements': result['totalElements']};
  }

  doDownloadAndStoreImage(MessageDto message) async {
    try {
      await FlutterDownloader.enqueue(
        url: message.fileUrl,
        savedDir: picturesPath,
        fileName: message.id.toString() + message.fileName,
        showNotification: false,
        openFileFromNotification: false,
      );
    } catch(exception) {
    }
  }

  onGetMessagesSuccess(result) async {
    scaffold.removeCurrentSnackBar();

    List fetchedMessages = result['messages'];
    totalMessages = result['totalElements'];

    MessageDto prevMessage;
    List<MessageSeenDto> unseenMessages = new List();
    messages.addAll(fetchedMessages.map((e) {
      var m = MessageDto.fromJson(e);

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

      if (m.messageType == 'IMAGE') {
        bool imageExists = File(picturesPath + '/' + m.id.toString() + m.fileName).existsSync();
        if (userId == m.receiver.id && !imageExists) {
          doDownloadAndStoreImage(m);
        }
      }

      return m;
    }).toList());

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

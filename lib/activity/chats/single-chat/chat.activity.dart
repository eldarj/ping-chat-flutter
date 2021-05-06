import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutterping/activity/calls/callscreen.activity.dart';
import 'package:flutterping/activity/chats/component/settings/chat-settings-menu.dart';
import 'package:flutterping/activity/chats/component/message/message.component.dart';
import 'package:flutterping/activity/chats/component/message/message.component.dart';
import 'package:flutterping/activity/chats/component/share-files/share-files.modal.dart';
import 'package:flutterping/activity/chats/single-chat/partial/chat-input-row.component.dart';
import 'package:flutterping/activity/chats/component/stickers/sticker-bar.dart';
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
import 'package:flutterping/service/messaging/message-sending.service.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';import 'package:flutterping/service/messaging/unread-message.publisher.dart';

import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
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

  final bool wasContactActivityPrevious;

  String statusLabel;

  ChatActivity({Key key, this.myContactName, this.peer,
    this.peerContactName, this.statusLabel, this.contactBindingId,
    this.wasContactActivityPrevious = false,
  }): messageSendingService = new MessageSendingService(peer, peerContactName, myContactName, contactBindingId), super(key: key);

  @override
  State<StatefulWidget> createState() => ChatActivityState(contactName: peerContactName);
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
  int userSentNodeId;

  String contactName;
  ContactDto contact;

  List<MessageDto> messages = new List();
  int totalMessages = 0;
  int pageNumber = 1;
  int pageSize = 50;

  bool previousWasPeerMessage;
  DateTime previousMessageDate;

  Function userPresenceSubscriptionFn;

  String picturesPath;

  bool isContactAdded = true;
  bool displayAddContactLoader = false;

  bool displayDeleteLoader = false;

  ChatActivityState({ this.contactName });

  onInit() async {
    CURRENT_OPEN_CONTACT_BINDING_ID = widget.contactBindingId;

    picturesPath = await new StorageIOService().getPicturesPath();

    var user = await UserService.getUser();
    userId = user.id;
    userSentNodeId = user.sentNodeId;

    doGetContactData();

    if (user.isActive) {
      PresenceEvent presenceEvent = new PresenceEvent();
      presenceEvent.userPhoneNumber = user.fullPhoneNumber;
      presenceEvent.status = true;

      sendPresenceEvent(presenceEvent);
    }

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
      if (['IMAGE', 'MEDIA', 'FILE', 'RECORDING'].contains(message.messageType)) {
        message.isDownloadingFile = true;
        message.downloadTaskId = await doDownloadAndStoreFile(message);
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

    dataSpaceDeletePublisher.addListener(STREAMS_LISTENER_ID, (int nodeId) {
      setState(() {
        for(var i = messages.length - 1; i >= 0; i--){
          if (messages[i].nodeId == nodeId) {
            setState(() {
              messages[i].deleted = true;
            });
          }
        }
      });
    });

    contactPublisher.onNameUpdate(STREAMS_LISTENER_ID, (ContactEvent contactEvent) {
      setState(() {
        this.contactName = contactEvent.value;
        this.contact.contactName = contactEvent.value;
      });
    });

    contactPublisher.onBackgroundUpdate(STREAMS_LISTENER_ID, (ContactEvent contactEvent) {
      setState(() {
        contact.backgroundImagePath = contactEvent.value;
      });
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
            message.isDownloadingFile = false;
          });
        });
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);

    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        setState(() {
          displaySendButton = visible;
        });
      },
    );

    textFocusNode.addListener(() {
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
    CURRENT_OPEN_CONTACT_BINDING_ID = 0;

    userPresenceSubscriptionFn();

    if (wsClientService != null) {
      wsClientService.sendingMessagesPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.receivingMessagesPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.incomingSentPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.incomingReceivedPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.incomingSeenPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.messageDeletedPub.removeListener(STREAMS_LISTENER_ID);
    }

    if (dataSpaceDeletePublisher != null) {
      dataSpaceDeletePublisher.removeListener(STREAMS_LISTENER_ID);
    }

    if (contactPublisher != null) {
      contactPublisher.removeListener(STREAMS_LISTENER_ID);
    }

    IsolateNameServer.removePortNameMapping(CHAT_ACTIVITY_DOWNLOADER_PORT_ID);

    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar.getBackAppBar(getScaffoldContext, centerTitle: false,
            titleWidget: InkWell(
              onTap: () async {
                await Future.delayed(Duration(milliseconds: 250));
                if (widget.wasContactActivityPrevious) {
                  Navigator.of(context).pop();
                } else {
                  NavigatorUtil.push(context, SingleContactActivity(
                    myContactName: contactName,
                    statusLabel: widget.statusLabel,
                    peer: widget.peer,
                    userId: userId,
                    contactName: contactName,
                    contactBindingId: widget.contactBindingId,
                    contactPhoneNumber: widget.peer.fullPhoneNumber,
                    favorite: false,
                    isContactAdded: isContactAdded,
                    wasChatActivityPrevious: true,
                  ));
                }
              },
              child: Container(
                padding: EdgeInsets.only(left: 5, right: 25),
                child: Row(
                  children: [
                    RoundProfileImageComponent(url: widget.peer?.profileImagePath,
                        height: 45, width: 45, borderRadius: 45, margin: 0),
                    Container(
                      margin: EdgeInsets.only(left: 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(contactName, style: TextStyle(fontWeight: FontWeight.normal)),
                        Text(widget.statusLabel, style: TextStyle(fontSize: 12, color: Colors.grey))
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    child: Icon(Icons.call, size: 20),
                    onTap: () {
                      NavigatorUtil.replace(context, new CallScreenWidget(
                        target: widget.peer.fullPhoneNumber,
                        contactName: contactName,
                        fullPhoneNumber: widget.peer.fullPhoneNumber,
                        profileImageWidget: widget.peer?.profileImagePath != null ? CachedNetworkImage(
                          imageUrl: widget.peer.profileImagePath, fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                              margin: EdgeInsets.all(15),
                              child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.grey.shade100)),
                        ) : null,
                        direction: 'OUTGOING',
                      ));
                    },
                  )
              ),
              displayDeleteLoader ? Container(width: 48, child: Align(child: Spinner(size: 20))) : ChatSettingsMenu(
                  userId: userId,
                  myContactName: widget.myContactName,
                  statusLabel: widget.statusLabel,
                  peer: widget.peer,
                  picturesPath: picturesPath,
                  peerContactName: contactName,
                  contactBindingId: widget.contactBindingId,
                  onDeleteContact: () {
                    doDeleteContact().then(onDeleteSuccess, onError: onDeleteError);
                  },
                  onDeleteMessages: () {
                    doDeleteMessages().then(onDeleteMessagesSuccess, onError: onDeleteMessagesError);
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
              Flexible(
                child: Stack(alignment: Alignment.topCenter, children: [
                  contact != null && contact.backgroundImagePath != null ? Positioned.fill(
                      child: Opacity(
                        opacity: 1,
                        child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: API_BASE_URL + '/files/chats/' + contact.backgroundImagePath),
                      )) : Container(),
                  buildMessagesList(),
                  buildAddToContactSection(),
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
              SingleChatInputRow(
                userId: userId,
                peerId: widget.peer.id,
                userSentNodeId: userSentNodeId,
                picturesPath: picturesPath,
                inputTextController: textController,
                inputTextFocusNode: textFocusNode, displayStickers: displayStickers, displaySendButton: displaySendButton,
                doSendMessage: doSendMessage, onOpenShareBottomSheet: onOpenShareBottomSheet, onOpenStickerBar: onOpenStickerBar,
                messageSendingService: widget.messageSendingService,
                onProgress: (message, progress) {
                  setState(() {
                    message.uploadProgress = progress / 100;
                  });
                },
              ),
              displayStickers ? StickerBar(sendFunc: doSendEmoji) : Container(),
            ]),
          );
        })
    );
  }

  Widget buildAddToContactSection() {
    Widget w = Container();

    if (!isContactAdded) {
      w = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
              padding: EdgeInsets.only(top: 5, bottom: 5, left: 15, right: 15),
              alignment: Alignment.center,
              color: new Color.fromRGBO(170, 170, 170, 0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('This user isn\'t in your contacts', style: TextStyle(
                      color: Colors.white
                  )),
                  TextButton(
                      onPressed: () {
                        doAddContact().then(onAddContactSuccess, onError: onAddContactError);
                      },
                      child: displayAddContactLoader ? Spinner(size: 20) : Text('Add', style: TextStyle(
                          color: Colors.grey.shade700)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade50,
                      ))
                ],
              )),
        ],
      );
    }

    return w;
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
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.8),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text('Here begins history. Say hello!', style: TextStyle(color: Colors.grey)),
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

    String widgetKey = message.text != null ? message.text : message.fileName;
    return MessageComponent(
      key: new Key(widgetKey),
      margin: EdgeInsets.only(top: isFirstMessage ? 20 : 0,
          left: 5, right: 5,
          bottom: isLastMessage ? 20 : 0),
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

    showCustomModalBottomSheet(
        context: context,
        builder: (context) => ShareFilesModal(
            userId: userId,
            userSentNodeId: userSentNodeId,
            peerId: widget.peer.id,
            picturesPath: picturesPath,
            myContactName: widget.myContactName,
            messageSendingService: widget.messageSendingService,
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

  doDownloadAndStoreFile(MessageDto message) async {
    try {
      return await FlutterDownloader.enqueue(
        url: message.fileUrl,
        savedDir: picturesPath,
        fileName: message.fileName,
        showNotification: false,
        openFileFromNotification: false,
      );
    } catch(exception) {
      print('Error downloading file on init.');
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
        '&contactUserId=' + widget.peer.id.toString();

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    dynamic result = response.decode();

    return {
      'messages': result['page'],
      'totalElements': result['totalElements'],
      // 'contact': result['additionalData']['contact']
      'isContactAdded': result['additionalData']['isContactAdded']
    };
  }

  onGetMessagesSuccess(result) async {
    scaffold.removeCurrentSnackBar();

    List fetchedMessages = result['messages'];
    totalMessages = result['totalElements'];
    // contact = ContactDto.fromJson(result['contact']);
    isContactAdded = result['isContactAdded'];

    MessageDto prevMessage;
    List<MessageSeenDto> unseenMessages = new List();
    var preparedMessages = fetchedMessages.map((e) async {
      var m = MessageDto.fromJson(e);

      // Download new file
      if (['IMAGE', 'MEDIA', 'FILE', 'RECORDING'].contains(m.messageType) && !m.deleted) {
        bool fileExists = File(picturesPath + '/' + m.id.toString() + m.fileName).existsSync();
        if (userId == m.receiver.id && !fileExists) {
          m.isDownloadingFile = true;
          m.downloadTaskId = await doDownloadAndStoreFile(m);
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

    unreadMessagePublisher.subject.add(widget.contactBindingId);

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

  Future<String> doAddContact() async {
    setState(() {
      displayAddContactLoader = true;
    });

    http.Response response = await HttpClientService.post('/api/contacts', body: new ContactDto(
      contactPhoneNumber: widget.peer.fullPhoneNumber,
      contactName: contactName,
    ));

    if (response.statusCode != 200) {
      throw new Exception();
    }

    var decode = json.decode(response.body);
    if (decode['error'] != null) {
      throw new Exception();
    }

    return contactName;
  }

  onAddContactSuccess(String contactName) async {
    setState(() {
      displayAddContactLoader = false;
      isContactAdded = true;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.success('You successfully added $contactName'
        ' to your contacts'));
  }

  onAddContactError(error) {
    setState(() {
      displayAddContactLoader = false;
      isContactAdded = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(duration: Duration(seconds: 2), actionOnPressed: () {
      setState(() { displayLoader = true; });
      doAddContact().then(onAddContactSuccess, onError: onAddContactError);
    }));
  }

  void doGetContactData() async {
    String url = '/api/contacts/${userId}/search/${widget.peer.id}';

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode == 200 && response.bodyBytes != null && response.bodyBytes.length > 0) {
      setState(() {
        contact = ContactDto.fromJson(response.decode());
      });
    }
  }

  // Delete contact
  Future<String> doDeleteContact() async {
    setState(() {
      displayDeleteLoader = true;
    });

    String url = '/api/contacts/${contact.id}/delete'
        '?contactBindingId=${contact.contactBindingId}'
        '&userId=${userId}';

    http.Response response = await HttpClientService.delete(url);

    await Future.delayed(Duration(seconds: 1));

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return contact.contactName;
  }

  void onDeleteSuccess(String contactName) async {
    setState(() {
      displayDeleteLoader = false;
    });

    contactPublisher.emitContactDelete(contact.contactBindingId);

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('Contact $contactName deleted'));

    await Future.delayed(Duration(seconds: 1));

    Navigator.of(context).pop();
  }

  void onDeleteError(error) {
    print(error);

    setState(() {
      displayDeleteLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(
        content: 'Something went wrong, please try again', duration: Duration(seconds: 2)
    ));
  }

  // Delete messages
  Future doDeleteMessages() async {
    setState(() {
      displayDeleteLoader = true;
    });

    String url = '/api/messages'
        '?contactBindingId=${widget.contactBindingId}'
        '&userId=${userId}';

    http.Response response = await HttpClientService.delete(url);

    await Future.delayed(Duration(seconds: 1));

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return;
  }

  void onDeleteMessagesSuccess(_) async {
    setState(() {
      displayDeleteLoader = false;
    });

    contactPublisher.emitAllMessagesDelete(widget.contactBindingId);

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('All messages deleted'));


    await Future.delayed(Duration(seconds: 1));

    Navigator.of(context).pop();
  }

  void onDeleteMessagesError(error) {
    print(error);

    setState(() {
      displayDeleteLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(
        content: 'Something went wrong, please try again', duration: Duration(seconds: 2)
    ));
  }
}


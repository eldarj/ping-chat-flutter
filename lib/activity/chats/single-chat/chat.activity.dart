import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutterping/activity/chats/component/gifs/gif-bar.component.dart';
import 'package:flutterping/activity/chats/component/message/info-message.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message.decoration.dart';
import 'package:flutterping/model/typing-event.model.dart';
import 'package:flutterping/service/gif/giphy.client.service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
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
import 'package:flutterping/model/reply-dto.model.dart';
import 'package:flutterping/service/contact/contact.publisher.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/messaging/image-download.publisher.dart';
import 'package:flutterping/service/messaging/message-deleted.publisher.dart';
import 'package:flutterping/service/messaging/message-edit.publisher.dart';
import 'package:flutterping/service/messaging/message-reply.publisher.dart';
import 'package:flutterping/service/messaging/message-pin.publisher.dart';
import 'package:flutterping/service/messaging/message-sending.service.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';import 'package:flutterping/service/messaging/unread-message.publisher.dart';

import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/jumping-dots/jumping-dots.component.dart';
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
import 'package:progress_indicators/progress_indicators.dart';
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

  // final Map firstMessagesPage;

  // final Function onFetchedFirstPage;

  String statusLabel;

  ChatActivity({Key key, this.myContactName, this.peer,
    this.peerContactName, this.statusLabel, this.contactBindingId,
    this.wasContactActivityPrevious = false,
    // this.onFetchedFirstPage,
  }): messageSendingService = new MessageSendingService(peer, peerContactName, myContactName, contactBindingId), super(key: key);

  @override
  State<StatefulWidget> createState() => ChatActivityState(contactName: peerContactName);
}

class ChatActivityState extends BaseState<ChatActivity> {
  static const String CHAT_ACTIVITY_DOWNLOADER_PORT_ID = "CHAT_ACTIVITY_DOWNLOADER_PORT_KEY";
  static const String STREAMS_LISTENER_ID = "ChatActivityListener";

  final FocusNode textFocusNode = new FocusNode();
  final TextEditingController textController = TextEditingController();

  bool displayLoader = true;
  bool displaySendButton = false;
  bool displayScrollLoader = false;
  bool displayScrollToBottom = false;

  bool displayStickers = false;
  bool displayGifs = false;

  int userId;
  int userSentNodeId;
  MessageTheme myMessageTheme;

  String contactName;
  ContactDto contact;

  List<MessageDto> messages = [];
  int totalMessages = 0;
  int pageNumber = 1;
  int pageSize = 50;

  Function userPresenceSubscriptionFn;

  String picturesPath;

  bool isContactAdded = true;
  bool displayAddContactLoader = false;

  bool displayDeleteLoader = false;

  bool isEditing = false;
  MessageDto editingMessage = null;

  bool isReplying = false;
  Widget replyWidget = Container();
  MessageDto replyMessage;

  ScrollController chatListController = new ScrollController();

  bool isPinButtonLoading = false;
  bool isDeleteSingleMessageLoading = false;
  bool isDeleteForEveryoneLoading = false;

  StateSetter messageActionsSetState;

  bool displaySenderTyping = false;

  ChatActivityState({ this.contactName });

  setMessageTheme(ClientDto user) {
    var chatBubbleColor;
    if (user.userSettings != null && user.userSettings.chatBubbleColorHex != null) {
      chatBubbleColor = CompanyColor.fromHexString(user.userSettings.chatBubbleColorHex);
    } else {
      chatBubbleColor = CompanyColor.myMessageBackground;
    }

    myMessageTheme = CompanyColor.messageThemes[chatBubbleColor];
  }

  onInit() async {
    CURRENT_OPEN_CONTACT_BINDING_ID = widget.contactBindingId;

    picturesPath = await new StorageIOService().getPicturesPath();

    var user = await UserService.getUser();
    setMessageTheme(user);

    userId = user.id;
    userSentNodeId = user.sentNodeId;

    doGetContactData();

    if (user.isActive) {
      PresenceEvent presenceEvent = new PresenceEvent();
      presenceEvent.userPhoneNumber = user.fullPhoneNumber;
      presenceEvent.status = true;

      sendPresenceEvent(presenceEvent);
    }

    // if (widget.firstMessagesPage != null) {
    //   onGetMessagesSuccess({
    //     'messages': widget.firstMessagesPage['page'],
    //     'totalElements': widget.firstMessagesPage['totalElements'],
    //     'isContactAdded': widget.firstMessagesPage['additionalData']['isContactAdded']
    //   });
    // }

    doGetMessages(clearData: true).then(onGetMessagesSuccess, onError: onGetMessagesError);
    userPresenceSubscriptionFn = wsClientService.subscribe('/users/${widget.peer.fullPhoneNumber}/status', (frame) async {
      PresenceEvent presenceEvent = PresenceEvent.fromJson(json.decode(frame.body));

      setState(() {
        widget.statusLabel = presenceEvent.status ? 'Online' : 'Last seen ' +
            DateTimeUtil.convertTimestampToTimeAgo(presenceEvent.eventTimestamp);
        wsClientService.presencePub.subject.add(presenceEvent);
      });
    });

    wsClientService.receivingMessagesPub.addListener(STREAMS_LISTENER_ID, (MessageDto message) async {
      if (['IMAGE', 'MEDIA', 'FILE', 'RECORDING', 'MAP_LOCATION'].contains(message.messageType)) {
        message.isDownloadingFile = true;
        message.downloadTaskId = await doDownloadAndStoreFile(message);
      }

      setState(() {
        messages.insert(0, message);
      });

      sendSeenStatus([new MessageSeenDto(id: message.id,
          senderPhoneNumber: message.sender.countryCode.dialCode + message.sender.phoneNumber)]);
    });

    wsClientService.editedMessagePub.addListener(STREAMS_LISTENER_ID, (MessageDto editedMessage) async {
      var message = messages.firstWhere((element) => element.id == editedMessage.id, orElse: () => null);
      if (message != null) {
        setState(() {
          message.edited = true;
          message.text = editedMessage.text;
        });
      }
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

    wsClientService.typingPub.addListener(STREAMS_LISTENER_ID, (TypingEvent typingEvent) async {
      if (!typingEvent.status) {
        setState(() {
          displaySenderTyping = false;
        });
      } else {
        setState(() {
          displaySenderTyping = true;
        });

        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            displaySenderTyping = false;
          });
        });
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
      setState(() {
        messages.removeWhere((element) => element.id == message.id);
      });

      // for(var i = messages.length - 1; i >= 0; i--){
      //   if (messages[i].id == message.id) {
      //     setState(() {
      //       messages[i].deleted = true;
      //     });
      //   }
      // }
    });

    dataSpaceDeletePublisher.addListener(STREAMS_LISTENER_ID, (int nodeId) {
      MessageDto message = messages.firstWhere((element) => element.nodeId == nodeId, orElse: () => null);
      if (message != null) {
        setState(() {
          message.filePath = null;
        });
      }

      // setState(() {
      //   for(var i = messages.length - 1; i >= 0; i--){
      //     if (messages[i].nodeId == nodeId) {
      //       setState(() {
      //         messages[i].deleted = true;
      //       });
      //     }
      //   }
      // });
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

    messagePinPublisher.onPinUpdate(STREAMS_LISTENER_ID, (PinEvent pinEvent) {
      var message = messages.firstWhere((element) => element.id == pinEvent.messageId, orElse: () => null);
      if (message != null) {
        setState(() {
          message.pinned = pinEvent.pinned;
        });
      }
    });

    messageEditPublisher.onEditEvent(STREAMS_LISTENER_ID, (EditEvent editEvent) {
      FocusScope.of(context).requestFocus(textFocusNode);

      setState(() {
        isEditing = true;
        editingMessage = editEvent.message;
        textController.text = editEvent.text;
      });
    });

    messageDeletedPublisher.onMessageDeleted(STREAMS_LISTENER_ID, (MessageDto message) {
      setState(() {
        messages.removeWhere((element) => element.id == message.id);
      });
    });

    messageReplyPublisher.onReplyEvent(STREAMS_LISTENER_ID, (MessageDto message) {
      FocusScope.of(context).requestFocus(textFocusNode);

      setState(() {
        isReplying = true;
        replyMessage = message;

        switch (message.messageType) {
          case 'RECORDING':
            replyWidget = Row(
              children: [
                Container(
                    margin: EdgeInsets.only(right: 5),
                    child: Icon(Icons.keyboard_voice, color: Colors.grey.shade500, size: 15)),
                Text('Recording', style: TextStyle(color: Colors.grey.shade500)),
              ],
            );
            break;
          case 'MEDIA':
            replyWidget = Row(
              children: [
                Container(
                    margin: EdgeInsets.only(right: 5),
                    child: Icon(Icons.ondemand_video, color: Colors.grey.shade500, size: 15)),
                Text('Media', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ) ;
            break;
          case 'FILE':
            replyWidget = Row(
              children: [
                Container(
                    margin: EdgeInsets.only(right: 5),
                    child: Icon(Icons.insert_drive_file, color: Colors.grey.shade500, size: 15)),
                Text('File', style: TextStyle(color: Colors.grey.shade500)),
              ],
            );
            break;
          case 'IMAGE':
            replyWidget = Row(
              children: [
                Container(
                    margin: EdgeInsets.only(right: 5),
                    child: Icon(Icons.photo_size_select_large, color: Colors.grey.shade500, size: 15)),
                Text('Image', style: TextStyle(color: Colors.grey.shade500)),
              ],
            );
            break;
          case 'MAP_LOCATION':
            replyWidget = Row(
              children: [
                Container(
                    margin: EdgeInsets.only(right: 5),
                    child: Icon(Icons.location_on_outlined, color: Colors.grey.shade500, size: 15)),
                Text('Location', style: TextStyle(color: Colors.grey.shade500)),
              ],
            );
            break;
          case 'STICKER':
            replyWidget = Row(
              children: [
                Container(
                    margin: EdgeInsets.only(right: 5),
                    child: Icon(Icons.sentiment_very_satisfied, color: Colors.grey.shade500, size: 15)),
                Text('Sticker', style: TextStyle(color: Colors.grey.shade500)),
              ],
            );
            break;
          case 'GIF':
            replyWidget = Row(
              children: [
                Container(
                    margin: EdgeInsets.only(right: 5),
                    child: Icon(Icons.gif_outlined, color: Colors.grey.shade500, size: 15)),
                Text('Gif', style: TextStyle(color: Colors.grey.shade500)),
              ],
            );
            break;
          default:
            replyWidget = Row(
              children: [
                Container(
                  child: Text(message.text,
                      overflow: TextOverflow.ellipsis, maxLines: 1,
                      style: TextStyle(color: Colors.grey.shade500)),
                ),
              ],
            );
        }
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

      if ([DownloadTaskStatus.complete, DownloadTaskStatus.failed].contains(status)) {
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
      wsClientService.editedMessagePub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.incomingSentPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.incomingReceivedPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.incomingSeenPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.messageDeletedPub.removeListener(STREAMS_LISTENER_ID);
      wsClientService.typingPub.removeListener(STREAMS_LISTENER_ID);
    }

    if (dataSpaceDeletePublisher != null) {
      dataSpaceDeletePublisher.removeListener(STREAMS_LISTENER_ID);
    }

    if (contactPublisher != null) {
      contactPublisher.removeListener(STREAMS_LISTENER_ID);
    }

    if (messagePinPublisher != null) {
      messagePinPublisher.removeListener(STREAMS_LISTENER_ID);
    }

    if (messageEditPublisher != null) {
      messageEditPublisher.removeListener(STREAMS_LISTENER_ID);
    }

    if (messageDeletedPublisher != null) {
      messageDeletedPublisher.removeListener(STREAMS_LISTENER_ID);
    }

    if (messageReplyPublisher != null) {
      messageReplyPublisher.removeListener(STREAMS_LISTENER_ID);
    }

    IsolateNameServer.removePortNameMapping(CHAT_ACTIVITY_DOWNLOADER_PORT_ID);

    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (displayStickers) {
          setState(() {
            displayStickers = false;
          });
          return false;
        }

        if (displayGifs) {
          setState(() {
            displayGifs = false;
          });
          return false;
        }

        return true;
      },
      child: Scaffold(
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
                          Text(contactName),
                          widget.statusLabel != ''
                            ? Text(widget.statusLabel, style: TextStyle(
                              fontSize: 12, color: Colors.grey))
                            : Container()
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
                      child: Icon(Icons.call, size: 20, color: CompanyColor.iconGrey),
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
                displayDeleteLoader
                    ? Container(width: 48, child: Align(child: Spinner(size: 20)))
                    : ChatSettingsMenu(
                        myMessageTheme,
                        userId: userId,
                        myContactName: widget.myContactName,
                        statusLabel: widget.statusLabel,
                        peer: widget.peer,
                        picturesPath: picturesPath,
                        peerContactName: contactName,
                        contactBindingId: widget.contactBindingId,
                        contact: contact,
                        onDeleteContact: () {
                          doDeleteContact().then(onDeleteSuccess, onError: onDeleteError);
                        },
                        onDeleteMessages: () {
                          doDeleteAllMessages().then(onDeleteAllMessagesSuccess, onError: onDeleteAllMessagesError);
                        },
                    )
              ]
          ),
          drawer: NavigationDrawerComponent(),
          body: Builder(builder: (context) {
            scaffold = Scaffold.of(context);
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
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
                        AnimatedOpacity(
                            duration: Duration(milliseconds: 500),
                            opacity: displayScrollToBottom ? 1 : 0,
                            child: Container(
                              alignment: Alignment.bottomRight,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    margin: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [Shadows.bottomShadow()]
                                    ),
                                    child: IconButton(
                                      color: CompanyColor.blueDark,
                                      onPressed: () {
                                        displayScrollToBottom = false;
                                        chatListController.jumpTo(0);
                                        setState(() {});
                                      },
                                      iconSize: 20,
                                      icon: Icon(Icons.arrow_downward_sharp),
                                    ),
                                  ),
                                ],
                              ),
                            )
                        ),
                        Container(
                            alignment: Alignment.bottomLeft,
                            child: AnimatedOpacity(
                              duration: Duration(milliseconds: 50),
                              opacity: displaySenderTyping ? 1 : 0,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                padding: EdgeInsets.only(left: 15, right: 15, bottom: 5, top: 5),
                                decoration: peerTypingBoxDecoration(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    JumpingDots(color: Colors.grey.shade400, dotSize: 12, dotSpacing: 2.5),
                                  ],
                                ),
                              ),
                            ))
                      ]),
                    ),
                    SingleChatInputRow(
                      userId: userId,
                      peerId: widget.peer.id,
                      contactPhoneNumber: contact?.contactPhoneNumber,
                      userSentNodeId: userSentNodeId,
                      picturesPath: picturesPath,
                      inputTextController: textController,
                      inputTextFocusNode: textFocusNode,
                      displayStickers: displayStickers,
                      displayGifs: displayGifs,
                      displaySendButton: displaySendButton,
                      messageSendingService: widget.messageSendingService,
                      doSendMessage: doSendMessage,
                      onOpenShareBottomSheet: onOpenShareBottomSheet,
                      onOpenStickerBar: onOpenStickerBar,
                      onOpenGifPicker: onOpenGifPicker,
                      onProgress: (message, progress) {
                        setState(() {
                          message.uploadProgress = progress / 100;
                        });
                      },
                      isEditing: isEditing,
                      onCancelEdit: () async {
                        FocusScope.of(context).unfocus();

                        setState(() {
                          isEditing = false;
                          editingMessage = null;
                          textController.text = '';
                        });
                      },
                      onSubmitEdit: () {
                        doSendEditMessage(editingMessage, textController.text);
                        FocusScope.of(context).unfocus();

                        setState(() {
                          isEditing = false;
                          editingMessage = null;
                          textController.text = '';
                        });
                      },
                      isReplying: isReplying,
                      replyWidget: replyWidget,
                      onCancelReply: () {
                        FocusScope.of(context).unfocus();

                        setState(() {
                          isReplying = false;
                          replyWidget = Container();
                          replyMessage = null;
                        });
                      },
                      onSubmitReply: doSendReply
                    ),
                  ]),
                ),
                displayGifs ? GifBar(sendFunc: doSendGif, onClose: closeGifPicker) : Container(),
                displayStickers ? StickerBar(
                    sendFunc: doSendEmoji,
                    onClose: closeStickerBar,
                ) : Container(),
              ],
            );
          })
      ),
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
                          color: CompanyColor.iconGrey)),
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
    Widget widget = Center(child: Spinner(padding: 5, backgroundColor: Colors.white));

    if (!displayLoader) {
      if (messages != null && messages.length > 0) {
        widget = NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {

            bool displayChange = false;
            if (!displayScrollToBottom && scrollInfo.metrics.pixels > 100) {
              displayScrollToBottom = true;
              displayChange = true;
            } else if (displayScrollToBottom && scrollInfo.metrics.pixels < 100) {
              displayScrollToBottom = false;
              displayChange = true;
            }

            if (displayChange) {
              Future.delayed(Duration(seconds: 1), () {
                setState(() {
                  //
                });
              });
            }

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
                controller: chatListController,
                itemCount: messages == null ? 0 : messages.length,
                itemBuilder: (context, index) => buildSingleMessage(
                    index,
                    messages[index],
                    isFirstMessage: index == messages.length - 1,
                    isLastMessage: index == 0
                ),
              ),
            ),
          ),
        );
      } else {
        widget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(25),
              margin: EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: Icon(Icons.chat, size: 50, color: Colors.white)
            ),
            Container(
                margin: EdgeInsets.only(bottom: 25),
                child: Text('Here begins history. Say hello!', style: TextStyle(color: Colors.grey))),
          ],
        );
      }
    }

    return widget;
  }

  Widget buildSingleMessage(int index, MessageDto message, {isLastMessage, isFirstMessage = false}) {
    Widget _w;

    bool nextIsSticker = false;
    bool chained = false;

    bool isPeerMessage = userId != message.sender.id;
    bool isPinnedMessage = message.pinned != null && message.pinned;

    if (!isLastMessage) {
      nextIsSticker = message.messageType == 'TEXT_MESSAGE' && messages[index - 1].messageType == 'STICKER';
      chained = message.sender.id == messages[index - 1].sender.id && !nextIsSticker;
    }

    DateTime thisMessageDate = DateTime.fromMillisecondsSinceEpoch(message.sentTimestamp);
    bool displayTimestamp = true;

    if (chained) {
      DateTime previousMessageDate = DateTime.fromMillisecondsSinceEpoch(messages[index - 1].sentTimestamp);
      int messagesTimeDiff = thisMessageDate.minute - previousMessageDate.minute;

      displayTimestamp = messagesTimeDiff.abs() > 5;
    }

    message.widgetKey = new GlobalKey();

    if (message.messageType == 'PIN_INFO') {
      _w = Container(
          margin: EdgeInsets.only(top: isFirstMessage ? 20 : 0, bottom: isLastMessage ? 25 : 0),
          child: InfoMessageComponent(key: message.widgetKey, message: message, isPeerMessage: isPeerMessage, isPinnedMessage: isPinnedMessage));
    } else if (isPeerMessage) {
      _w = PeerMessageComponent(
        key: message.widgetKey,
        margin: EdgeInsets.only(top: isFirstMessage ? 20 : 0,
            left: 5, right: 5,
            bottom: isLastMessage ? 25 : 0),
        message: message,
        chained: chained,
        isPinnedMessage: isPinnedMessage,
        picturesPath: picturesPath,
        onMessageTapDown: () => onMessageTapDown(message, isPeerMessage: true)
      );

    } else {
      _w = MessageComponent(
        myMessageTheme,
        key: message.widgetKey,
        margin: EdgeInsets.only(top: isFirstMessage ? 20 : 0,
            left: 5, right: 5,
            bottom: isLastMessage ? 25 : 0),
        message: message,
        chained: chained,
        displayTimestamp: displayTimestamp,
        isPinnedMessage: isPinnedMessage,
        picturesPath: picturesPath,
        onMessageTapDown: () => onMessageTapDown(message)
      );
    }

    return Container(
      child: _w
    );
  }

  onOpenStickerBar() {
    FocusScope.of(context).requestFocus(new FocusNode());
    setState(() {
      displayStickers = true;
    });
  }

  closeStickerBar() {
    setState(() {
      displayStickers = false;
    });
  }

  onOpenGifPicker() async {
    FocusScope.of(context).requestFocus(new FocusNode());
    setState(() {
      displayGifs = true;
    });
  }

  closeGifPicker() {
    setState(() {
      displayGifs = false;
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
    chatListController.animateTo(0.0, curve: Curves.easeOut, duration: Duration(milliseconds: 50));
  }

  doSendGif(String gifUrl) async {
    widget.messageSendingService.sendGif(gifUrl);
    chatListController.animateTo(0.0, curve: Curves.easeOut, duration: Duration(milliseconds: 50));
  }

  doSendMessage() {
    if (textController.text.length > 0) {
      sendTypingEvent(contact.contactPhoneNumber, false);
      widget.messageSendingService.sendTextMessage(textController.text);

      setState(() {
        textController.clear();
      });

      chatListController.animateTo(0.0, curve: Curves.easeOut, duration: Duration(milliseconds: 50));
    }
  }

  doSendEditMessage(MessageDto message, String text) async {
    // String url = '/api/messages/$messageId';
    // await HttpClientService.post(url, body: text);
    widget.messageSendingService.sendEdit(message, text);
  }

  doSendReply() {
    FocusScope.of(context).unfocus();

    if (textController.text.length > 0) {
      widget.messageSendingService.sendReply(textController.text, replyMessage);
    }

    setState(() {
      isReplying = false;
      replyWidget = Container();
      replyMessage = null;
      textController.clear();
    });

    chatListController.animateTo(0.0, curve: Curves.easeOut, duration: Duration(milliseconds: 50));
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

  Future doGetMessages({page = 1, clearData = false, favouritesOnly = false}) async {
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

    if (clearData) {
      messages.clear();
      pageNumber = 1;
      // widget.onFetchedFirstPage(result);
    }


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

      if (m.receiver.id == userId && !m.seen) {
        // Download new file
        // if (['IMAGE', 'MEDIA', 'FILE', 'RECORDING'].contains(m.messageType) && !m.deleted) {
        if (['IMAGE', 'MEDIA', 'FILE', 'RECORDING'].contains(m.messageType)) {
          bool fileExists = File(picturesPath + '/' + m.id.toString() + m.fileName).existsSync();
          if (!fileExists) {
            m.isDownloadingFile = true;
            m.downloadTaskId = await doDownloadAndStoreFile(m);
          }
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

      doGetMessages(clearData: true).then(onGetMessagesSuccess, onError: onGetMessagesError);
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
        ' to your contacts',
        duration: Duration(seconds: 4)
    ));
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

    await Future.delayed(Duration(seconds: 3));

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

  // Build message actions
  Widget buildTextMessageActions(message) {
    return Wrap(children: [
      buildReplyTile(message),
      buildCopyTile(message),
      buildEditTile(message),
      buildPinTile(message),
      buildDeleteTile(message),
      buildDeleteForEveryoneTile(message),
    ]);
  }

  Widget buildGifMessageActions(message) {
    return Wrap(children: [
      buildReplyTile(message),
      buildPinTile(message),
      buildDeleteTile(message),
      buildDeleteForEveryoneTile(message),
    ]);
  }

  Widget buildStickerMessageActions(message) {
    return Wrap(children: [
      buildReplyTile(message),
      buildPinTile(message),
      buildDeleteTile(message),
      buildDeleteForEveryoneTile(message),
    ]);
  }

  Widget buildImageMessageActions(message) {
    return Wrap(children: [
      buildReplyTile(message),
      buildPinTile(message),
      buildDeleteTile(message),
      buildDeleteForEveryoneTile(message),
    ]);
  }

  Widget buildMapMessageActions(message) {
    return Wrap(children: [
      buildReplyTile(message),
      buildCopyTile(message),
      buildPinTile(message),
      buildDeleteTile(message),
      buildDeleteForEveryoneTile(message),
    ]);
  }

  Widget buildMediaMessageActions(message) {
    return Wrap(children: [
      buildReplyTile(message),
      buildPinTile(message),
      buildDeleteTile(message),
      buildDeleteForEveryoneTile(message),
    ]);
  }

  Widget buildPeerTextActions(message) {
    return Wrap(children: [
      buildReplyTile(message),
      buildCopyTile(message),
      buildPinTile(message),
      buildDeleteTile(message)
    ]);
  }

  Widget buildPeerActions(message) {
    return Wrap(children: [
      buildReplyTile(message),
      buildPinTile(message),
      buildDeleteTile(message),
    ]);
  }

  // Message tap actions widgets
  void onMessageTapDown(message, { isPeerMessage = false }) async {
    FocusScope.of(ROOT_CONTEXT).requestFocus(new FocusNode());

    Function actionsWidget;

    if (isPeerMessage) {
      if (message.messageType == 'TEXT_MESSAGE') {
        actionsWidget = buildPeerTextActions;
      } else {
        actionsWidget = buildPeerActions;
      }
    } else {
      switch (message.messageType) {
        case 'RECORDING':
          actionsWidget = buildMediaMessageActions;
          break;
        case 'MEDIA':
          actionsWidget = buildMediaMessageActions;
          break;
        case 'FILE':
          actionsWidget = buildMediaMessageActions;
          break;
        case 'IMAGE':
          actionsWidget = buildImageMessageActions;
          break;
        case 'MAP_LOCATION':
          actionsWidget = buildMapMessageActions;
          break;
        case 'STICKER':
          actionsWidget = buildStickerMessageActions;
          break;
        case 'GIF':
          actionsWidget = buildGifMessageActions;
          break;
        default:
          actionsWidget = buildTextMessageActions;
      }
    }

    showModalBottomSheet(context: context, builder: (BuildContext context) {
      return StatefulBuilder(
          builder: (context, stater) {
            messageActionsSetState = stater;
            return actionsWidget.call(message);
          }
      );
    });
  }

  buildReplyTile(message) {
    return ListTile(
        dense: true,
        leading: Icon(Icons.reply, size: 20, color: Colors.grey.shade600),
        title: Text('Reply'),
        onTap: () {
          Navigator.of(ROOT_CONTEXT).pop();
          messageReplyPublisher.emitReplyEvent(message);
        });
  }

  buildCopyTile(message) {
    return ListTile(
        dense: true,
        leading: Icon(Icons.copy, size: 20, color: Colors.grey.shade600),
        title: Text('Copy'),
        onTap: () {
          FlutterClipboard.copy(message.text).then(( value ) {
            Navigator.of(ROOT_CONTEXT).pop();
            scaffold.showSnackBar(SnackBarsComponent.info('Copied to clipboard'));
          });
        });
  }

  buildPinTile(message) {
    return ListTile(
        dense: true,
        leading: isPinButtonLoading ? Spinner(size: 20) : Icon(Icons.push_pin, size: 20, color: Colors.grey.shade600),
        title: Text(message.pinned != null && message.pinned ? 'Unpin' : 'Pin'),
        onTap: () {
          doUpdatePinStatus(message).then((pinned) => onPinSuccess(message, pinned), onError: onPinError);
        });
  }

  buildEditTile(message) {
    return ListTile(
        dense: true,
        leading: Icon(Icons.edit, size: 20, color: Colors.grey.shade600),
        title: Text('Edit'),
        onTap: () {
          Navigator.of(ROOT_CONTEXT).pop();
          messageEditPublisher.emitEditEvent(message, message.text);
        });
  }

  buildDeleteTile(message) {
    return ListTile(
        dense: true,
        leading: isDeleteSingleMessageLoading ? Spinner(size: 20) : Icon(Icons.delete_outlined, size: 20, color: Colors.grey.shade600),
        title: Text('Delete for myself'),
        onTap: () {
          doDeleteSingleMessage(message, deleteForEveryone: false).then(onDeleteSingleMessageSuccess, onError: onDeleteSingleMessageError);
        });
  }

  buildDeleteForEveryoneTile(message) {
    return ListTile(
        dense: true,
        leading: isDeleteForEveryoneLoading ? Spinner(size: 20) : Icon(Icons.delete, size: 20, color: Colors.grey.shade600),
        title: Text('Delete for everyone'),
        onTap: () {
          doDeleteSingleMessage(message, deleteForEveryone: true)
              .then(onDeleteSingleMessageSuccess, onError: onDeleteSingleMessageError);
        });
  }


  // Delete all messages
  Future doDeleteAllMessages() async {
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

  void onDeleteAllMessagesSuccess(_) async {
    setState(() {
      displayDeleteLoader = false;
    });

    contactPublisher.emitAllMessagesDelete(widget.contactBindingId);

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('All messages deleted'));


    await Future.delayed(Duration(seconds: 3));

    Navigator.of(context).pop();
  }

  void onDeleteAllMessagesError(error) {
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
  Future<MessageDto> doDeleteSingleMessage(MessageDto message, { bool deleteForEveryone: false }) async {
    messageActionsSetState(() {
      if (deleteForEveryone) {
        isDeleteForEveryoneLoading = true;
      } else {
        isDeleteSingleMessageLoading = true;
      }
    });

    String url = '/api/messages/${message.id}'
        '?userId=$userId'
        '&deleteForEveryone=$deleteForEveryone';

    http.Response response = await HttpClientService.delete(url);

    await Future.delayed(Duration(seconds: 1));

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return message;
  }

  void onDeleteSingleMessageSuccess(MessageDto message) async {
    messageDeletedPublisher.emitMessageDeleted(message);

    isDeleteSingleMessageLoading = false;
    isDeleteForEveryoneLoading = false;

    Navigator.of(ROOT_CONTEXT).pop();
  }

  void onDeleteSingleMessageError(error) {
    print(error);

    isDeleteSingleMessageLoading = false;
    isDeleteForEveryoneLoading = false;

    Navigator.of(ROOT_CONTEXT).pop();
  }

  // Pin message
  Future<bool> doUpdatePinStatus(MessageDto message) async {
    messageActionsSetState(() {
      isPinButtonLoading = true;
    });

    String url = '/api/messages/${message.id}/pin';

    message.pinned = message.pinned != null && message.pinned;
    http.Response response = await HttpClientService.post(url, body: !message.pinned);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    await Future.delayed(Duration(seconds: 1));

    return !message.pinned;
  }

  onPinSuccess(message, pinned) {
    widget.messageSendingService.sendPinnedInfoMessage(pinned);

    setState(() {
      message.pinned = pinned;
    });

    isPinButtonLoading = false;
    messagePinPublisher.emitPinUpdate(message.id, pinned);

    Navigator.of(ROOT_CONTEXT).pop();
  }

  onPinError(error) {
    print(error);

    isPinButtonLoading = false;

    Navigator.of(ROOT_CONTEXT).pop();
  }
}


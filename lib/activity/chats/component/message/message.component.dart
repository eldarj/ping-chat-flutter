import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-content.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-decoration.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-status.dart';
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

class MessageComponent extends StatefulWidget {
  final MessageDto message;

  final bool displayTimestamp;

  final EdgeInsets margin;

  final String picturesPath;

  final bool isPeerMessage;

  final bool pinnedStyle;

  const MessageComponent({Key key,
    this.message,
    this.isPeerMessage,
    this.displayTimestamp,
    this.margin,
    this.picturesPath,
    this.pinnedStyle = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => MessageComponentState();
}

class MessageComponentState extends State<MessageComponent> {
  ScaffoldState scaffold;

  StateSetter messageActionsSetState;

  double maxWidth = DEVICE_MEDIA_SIZE.width - 150;

  AudioPlayer audioPlayer = AudioPlayer();

  String recordingCurrentPosition = '00:00';

  bool isPinButtonLoading = false;

  @override
  void initState() {
    super.initState();
    AudioPlayer.logEnabled = false;
    audioPlayer.onAudioPositionChanged.listen((Duration  p) {
      setState(() {
        recordingCurrentPosition = p.format();
      });
    });

    audioPlayer.onPlayerStateChanged.listen((AudioPlayerState audioPlayerState) {
      setState(() {
        widget.message.isRecordingPlaying = audioPlayerState == AudioPlayerState.PLAYING;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    scaffold = Scaffold.of(context);

    return GestureDetector(
      onTapUp: resolveMessageTapHandler(),
      onLongPressStart: (_) {
        onMessageTapDown(widget.message, widget.isPeerMessage);
      },
      onDoubleTap: () {
        onMessageTapDown(widget.message, widget.isPeerMessage);
      },
      child: Container(
        margin: widget.margin,
        child: Container(
          margin: EdgeInsets.only(left: 5, right: 5, top: 5, bottom: widget.displayTimestamp ? 20 : 2.5),
          child: Column(crossAxisAlignment: widget.isPeerMessage ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                buildMessagePinDetails(),
                buildMessageContent(),
                buildMessageStatus(),
              ]),
        ),
      ),
    );
  }

  buildMessagePinDetails() {
    return widget.pinnedStyle && widget.message.pinned ? Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade100),
        ),
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        margin: EdgeInsets.only(bottom: 5),
        child: Text('Pinned on ${DateTimeUtil.convertTimestampToDate(widget.message.pinnedTimestamp)}', style: TextStyle(
            color: CompanyColor.blueDark,
        ))
    ) : Container();
  }

  buildMessageStatus() {
    return MessageStatusRow(widget.isPeerMessage,
        widget.message.sentTimestamp,
        widget.message.displayCheckMark,
        widget.displayTimestamp,
        widget.message.sent,
        widget.message.received,
        widget.message.seen,
        widget.message.pinned,
        widget.message.edited);
  }

  buildMessageMedia(MessageDto message, filePath, isDownloadingFile, isUploading, uploadProgress, stopUploadFunc) {
    String desc = message.fileSizeFormatted();
    String title = message.fileName;

    var iconBg = widget.isPeerMessage ? CompanyColor.blueDark : CompanyColor.accentGreenLight;

    IconData icon = message.messageType == 'MEDIA' ? Icons.ondemand_video : Icons.file_copy_outlined;
    Widget iconWidget = Icon(icon, color: Colors.grey.shade100, size: 20);

    if (message.messageType == 'RECORDING') {
      title = 'Recording';
      IconData icon = message.isRecordingPlaying ? Icons.pause : Icons.mic_none;

      if (message.recordingDuration != null) {
        title += ' (${message.recordingDuration})';
      }

      iconWidget = Stack(
        alignment: Alignment.center,
        children: [
          Container(
              margin: EdgeInsets.only(bottom: message.isRecordingPlaying ? 12.5 : 0),
              child: Icon(icon, color: Colors.grey.shade100, size: 20)),
          Container(
              margin: EdgeInsets.only(top: message.isRecordingPlaying ? 12.5 : 0),
              child: Text(recordingCurrentPosition, style: TextStyle(
                  fontSize: 11,
                  color: message.isRecordingPlaying ? Colors.grey.shade100 : Colors.transparent))
          ),
        ],
      );
    }

    return Container(
        padding: EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: maxWidth, minWidth: maxWidth),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 10),
              child: isUploading ? GestureDetector(onTap: stopUploadFunc, child: Container(
                  width: 50, height: 50, child: UploadProgressIndicator(size: 50, progress: uploadProgress))) :
              isDownloadingFile ? Container(height: 50, width: 50,
                  alignment: Alignment.center,
                  child: Spinner()) :
              Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: iconBg
                  ),
                  child: iconWidget
              ),
            ),
            Container(
              width: maxWidth - 100,
              alignment: Alignment.centerLeft,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title),
                    Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ]),
            )
          ],
        ));
  }

  buildMessageContent() {
    Widget _messageWidget;

    var displayPinnedBorder = widget.message.pinned != null && widget.message.pinned && !widget.pinnedStyle;
    BoxDecoration messageDecoration = widget.isPeerMessage ? peerTextBoxDecoration(displayPinnedBorder) : myTextBoxDecoration(displayPinnedBorder);

    if (widget.message.deleted) {
      print('MESSAGE DELETED');
      _messageWidget = MessageDeleted();

    } else if (['MEDIA', 'FILE'].contains(widget.message.messageType??'')) {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.fileName
          : widget.message.filePath;

      _messageWidget = buildMessageMedia(widget.message, filePath, widget.message.isDownloadingFile,
          widget.message.isUploading, widget.message.uploadProgress, widget.message.stopUploadFunc);

    } else if (widget.message.messageType == 'RECORDING') {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.fileName
          : widget.message.filePath;

      _messageWidget = buildMessageMedia(widget.message, filePath, widget.message.isDownloadingFile,
          widget.message.isUploading, widget.message.uploadProgress, widget.message.stopUploadFunc);

    } else if (widget.message.messageType == 'IMAGE') {
      print('MESSAGE IMAGE');
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.fileName
          : widget.message.filePath;

      _messageWidget = MessageImage(filePath, widget.message.isDownloadingFile, widget.message.isUploading,
          widget.message.uploadProgress, widget.message.stopUploadFunc);
      messageDecoration = imageDecoration(widget.message.pinned);

    } else if (widget.message.messageType == 'STICKER') {
      _messageWidget = MessageSticker(widget.message.text);
      messageDecoration = stickerBoxDecoration();

    } else if (widget.message.messageType == 'MAP_LOCATION') {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.fileName
          : widget.message.filePath;

      _messageWidget = MessageImage(filePath, widget.message.isDownloadingFile, widget.message.isUploading,
          widget.message.uploadProgress, widget.message.stopUploadFunc, text: widget.message.text);
      messageDecoration = imageDecoration(widget.message.pinned, isPeerMessage: widget.isPeerMessage);
    } else {
      _messageWidget = MessageText(widget.message.text, edited: widget.message.edited);
    }

    Widget w;

    if (widget.message.replyMessage != null) {
      w = Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Color.fromRGBO(240, 240, 240, 0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(crossAxisAlignment: widget.isPeerMessage
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
          children: [
            ReplyComponent(
              message: widget.message,
              isPeerMessage: widget.isPeerMessage,
              picturesPath: widget.picturesPath,
            ),
            Container(
                decoration: messageDecoration,
                constraints: BoxConstraints(maxWidth: maxWidth), // TODO: Check max height
                child: _messageWidget)
          ]
        )
      );
    } else {
      w = Container(
          decoration: messageDecoration,
          constraints: BoxConstraints(maxWidth: maxWidth), // TODO: Check max height
          child: _messageWidget);
    }

    return w;
  }

  buildReplyMessage() {
    Widget w = Container();
    if (widget.message.replyMessage != null) {
      return ReplyComponent(
          message: widget.message,
          isPeerMessage: widget.isPeerMessage,
          picturesPath: widget.picturesPath,
      );
    }

    return w;
  }

  // Message tap handler
  resolveMessageTapHandler() {
    Function messageTapHandler = (_) {};

    if (widget.message.deleted) {
      messageTapHandler = (_) {};

    } else if (['MEDIA', 'FILE'].contains(widget.message.messageType ?? '')) {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.fileName
          : widget.message.filePath;

      messageTapHandler = (_) async {
        OpenFile.open(filePath);
      };

    } else if (widget.message.messageType == 'RECORDING') {
      if (!widget.message.isUploading) {
        String filePath = widget.isPeerMessage
            ? widget.picturesPath + '/' + widget.message.fileName
            : widget.message.filePath;

        messageTapHandler = (_) async {
          if (widget.message.isRecordingPlaying) {
            await audioPlayer.stop();
          } else {
            await audioPlayer.play(filePath, isLocal: true);
          }
        };
      }

    } else if (widget.message.messageType == 'IMAGE') {
      if (!widget.message.isUploading) {
        String filePath = widget.isPeerMessage
            ? widget.picturesPath + '/' + widget.message.fileName
            : widget.message.filePath;

        messageTapHandler = (_) async {
          NavigatorUtil.push(context,
              ImageViewerActivity(message: widget.message,
                  messageId: widget.message.id,
                  sender: widget.message.senderContactName,
                  timestamp: widget.message.sentTimestamp,
                  file: File(filePath)));
        };
      }
    } else if (widget.message.messageType == 'MAP_LOCATION') {
      if (!widget.message.isUploading) {
        String filePath = widget.isPeerMessage
            ? widget.picturesPath + '/' + widget.message.fileName
            : widget.message.filePath;

        messageTapHandler = (_) async {
          NavigatorUtil.push(context,
              ImageViewerActivity(message: widget.message,
                  messageId: widget.message.id,
                  sender: widget.message.senderContactName,
                  timestamp: widget.message.sentTimestamp,
                  file: File(filePath))
          );
        };
      }
    }

    return messageTapHandler;
  }

  // Delete message
  Future doDeleteMessage(message) async {
    String url = '/api/messages/' + message.id.toString();

    if (message.fileName != null) {
      String filePath = widget.picturesPath + '/' + message.fileName;
      File(filePath).delete();
    }

    http.Response response = await HttpClientService.delete(url);

    if (response.statusCode != 200) {
      throw Exception();
    }

    return true;
  }

  onDeleteMessageSuccess(_) async {
    setState(() {
      widget.message.deleted = true;
    });
  }

  onDeleteMessageError(error) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
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
    isPinButtonLoading = false;
    Navigator.of(context).pop();

    setState(() {
      message.pinned = pinned;
    });

    messagePinPublisher.emitPinUpdate(message.id, pinned);

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.success(pinned ? 'Message pinned'
        : 'Message unpinned'));
  }

  onPinError(error) {
    print(error);
    isPinButtonLoading = false;
    Navigator.of(context).pop();

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(content: 'Something went wrong'));
  }

  // Message tap actions widgets
  void onMessageTapDown(MessageDto message, bool isPeerMessage) async {
    FocusScope.of(context).requestFocus(new FocusNode());

    Widget actionsWidget;

    switch (message.messageType) {
      case 'RECORDING':
        actionsWidget = buildMediaMessageActions(message);
        break;
      case 'MEDIA':
        actionsWidget = buildMediaMessageActions(message);
        break;
      case 'FILE':
        actionsWidget = buildMediaMessageActions(message);
        break;
      case 'IMAGE':
        actionsWidget = buildImageMessageActions(message);
        break;
      case 'MAP_LOCATION':
        actionsWidget = buildMapMessageActions(message);
        break;
      case 'STICKER':
        actionsWidget = buildStickerMessageActions(message);
        break;
      default:
        actionsWidget = buildTextMessageActions(message);
    }

    showModalBottomSheet(context: context, builder: (BuildContext context) {
      return actionsWidget;
    });
  }

  Widget buildTextMessageActions(message) {
    return StatefulBuilder(builder: (context, setState) {
      messageActionsSetState = setState;
      return Wrap(children: [
        ListTile(
            dense: true,
            leading: Icon(Icons.reply, size: 20, color: Colors.grey.shade600),
            title: Text('Reply'),
            onTap: () {
              Navigator.of(context).pop();
              messageReplyPublisher.emitReplyEvent(message);
            }),
        ListTile(
            dense: true,
            leading: Icon(Icons.copy, size: 20, color: Colors.grey.shade600),
            title: Text('Copy'),
            onTap: () {
              FlutterClipboard.copy(message.text).then(( value ) {
                Navigator.of(context).pop();
                scaffold.showSnackBar(SnackBarsComponent.info('Copied to clipboard'));
              });
            }),
        ListTile(
            dense: true,
            leading: Icon(Icons.edit, size: 20, color: Colors.grey.shade600),
            title: Text('Edit'),
            onTap: () {
              Navigator.of(context).pop();
              messageEditPublisher.emitEditEvent(message.id, message.text);
            }),
        ListTile(
            dense: true,
            leading: isPinButtonLoading ? Spinner(size: 20) : Icon(Icons.push_pin, size: 20, color: Colors.grey.shade600),
            title: Text(message.pinned != null && message.pinned ? 'Unpin' : 'Pin'),
            onTap: () {
              doUpdatePinStatus(message).then((pinned) => onPinSuccess(message, pinned), onError: onPinError);
            }),
        ListTile(dense: true, leading: Icon(Icons.delete_outlined, size: 20, color: Colors.grey.shade600),
            title: Text('Delete'),
            onTap: () {}),
      ]);
    });
  }

  Widget buildStickerMessageActions(message) {
    return StatefulBuilder(builder: (context, setState) {
      messageActionsSetState = setState;
      return Wrap(children: [
        ListTile(
            dense: true,
            leading: Icon(Icons.reply, size: 20, color: Colors.grey.shade600),
            title: Text('Reply'),
            onTap: () {
              Navigator.of(context).pop();
              messageReplyPublisher.emitReplyEvent(message);
            }),
        ListTile(
            dense: true,
            leading: isPinButtonLoading ? Spinner(size: 20) : Icon(Icons.push_pin, size: 20, color: Colors.grey.shade600),
            title: Text(message.pinned != null && message.pinned ? 'Unpin' : 'Pin'),
            onTap: () {
              doUpdatePinStatus(message).then((pinned) => onPinSuccess(message, pinned), onError: onPinError);
            }),
        ListTile(dense: true, leading: Icon(Icons.delete_outlined, size: 20, color: Colors.grey.shade600),
            title: Text('Delete'),
            onTap: () {}),
      ]);
    });
  }

  Widget buildImageMessageActions(message) {
    return StatefulBuilder(builder: (context, setState) {
      messageActionsSetState = setState;
      return Wrap(children: [
        ListTile(
            dense: true,
            leading: Icon(Icons.reply, size: 20, color: Colors.grey.shade600),
            title: Text('Reply'),
            onTap: () {
              Navigator.of(context).pop();
              messageReplyPublisher.emitReplyEvent(message);
            }),
        ListTile(
            dense: true,
            leading: isPinButtonLoading ? Spinner(size: 20) : Icon(Icons.push_pin, size: 20, color: Colors.grey.shade600),
            title: Text(message.pinned != null && message.pinned ? 'Unpin' : 'Pin'),
            onTap: () {
              doUpdatePinStatus(message).then((pinned) => onPinSuccess(message, pinned), onError: onPinError);
            }),
        ListTile(dense: true, leading: Icon(Icons.delete_outlined, size: 20, color: Colors.grey.shade600),
            title: Text('Delete'),
            onTap: () {}),
      ]);
    });
  }

  Widget buildMapMessageActions(message) {
    return StatefulBuilder(
        builder: (context, setState) {
          messageActionsSetState = setState;
          return Wrap(children: [
            ListTile(
                dense: true,
                leading: Icon(Icons.reply, size: 20, color: Colors.grey.shade600),
                title: Text('Reply'),
                onTap: () {
                  Navigator.of(context).pop();
                  messageReplyPublisher.emitReplyEvent(message);
                }),
            ListTile(
                dense: true,
                leading: Icon(Icons.copy, size: 20, color: Colors.grey.shade600),
                title: Text('Copy'),
                onTap: () {
                  FlutterClipboard.copy(message.text).then(( value ) {
                    Navigator.of(context).pop();
                    scaffold.showSnackBar(SnackBarsComponent.info('Copied to clipboard'));
                  });
                }),
            ListTile(
                dense: true,
                leading: isPinButtonLoading ? Spinner(size: 20) : Icon(Icons.push_pin, size: 20, color: Colors.grey.shade600),
                title: Text(message.pinned != null && message.pinned ? 'Unpin' : 'Pin'),
                onTap: () {
                  doUpdatePinStatus(message).then((pinned) => onPinSuccess(message, pinned), onError: onPinError);
                }),
            ListTile(dense: true, leading: Icon(Icons.delete_outlined, size: 20, color: Colors.grey.shade600),
                title: Text('Delete'),
                onTap: () {}),
          ]);
        });
  }

  Widget buildMediaMessageActions(message) {
    return StatefulBuilder(
        builder: (context, setState) {
          messageActionsSetState = setState;
          return Wrap(children: [
            ListTile(
                dense: true,
                leading: Icon(Icons.reply, size: 20, color: Colors.grey.shade600),
                title: Text('Reply'),
                onTap: () {
                  Navigator.of(context).pop();
                  messageReplyPublisher.emitReplyEvent(message);
                }),
            ListTile(
                dense: true,
                leading: isPinButtonLoading ? Spinner(size: 20) : Icon(Icons.push_pin, size: 20, color: Colors.grey.shade600),
                title: Text(message.pinned != null && message.pinned ? 'Unpin' : 'Pin'),
                onTap: () {
                  doUpdatePinStatus(message).then((pinned) => onPinSuccess(message, pinned), onError: onPinError);
                }),
            ListTile(dense: true, leading: Icon(Icons.delete_outlined, size: 20, color: Colors.grey.shade600),
                title: Text('Delete'),
                onTap: () {}),
          ]);
        });
  }
}

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

class PeerMessageComponent extends StatefulWidget {
  final MessageDto message;

  final bool displayTimestamp;

  final EdgeInsets margin;

  final String picturesPath;

  final bool pinnedStyle;

  final Function onMessageTapDown;

  const PeerMessageComponent({Key key,
    this.message,
    this.displayTimestamp,
    this.margin,
    this.picturesPath,
    this.pinnedStyle = false,
    this.onMessageTapDown
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => PeerMessageComponentState();
}

class PeerMessageComponentState extends State<PeerMessageComponent> {
  ScaffoldState scaffold;

  StateSetter messageActionsSetState;

  double maxWidth = DEVICE_MEDIA_SIZE.width - 150;

  AudioPlayer audioPlayer = AudioPlayer(); // TODO: Optimize, one per app not per message

  String recordingCurrentPosition = '00:00';

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
        widget.onMessageTapDown.call();
      },
      onDoubleTap: () {
        widget.onMessageTapDown.call();
      },
      child: Container(
        margin: widget.margin,
        child: Container(
          margin: EdgeInsets.only(left: 5, right: 5, top: 2.5, bottom: widget.displayTimestamp ? 20 : 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
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
    return MessageStatusRow(
        true,
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
                      color: CompanyColor.blueDark
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

    BoxDecoration messageDecoration = peerTextBoxDecoration(
        displayPinnedBorder,
        displayBubble: widget.displayTimestamp
    );

    if (widget.message.deleted) {
      print('MESSAGE DELETED');
      _messageWidget = MessageDeleted();

    } else if (['MEDIA', 'FILE'].contains(widget.message.messageType??'')) {
      String filePath = widget.picturesPath + '/' + widget.message.fileName;

      _messageWidget = buildMessageMedia(widget.message, filePath, widget.message.isDownloadingFile,
          widget.message.isUploading, widget.message.uploadProgress, widget.message.stopUploadFunc);

    } else if (widget.message.messageType == 'RECORDING') {
      String filePath = widget.picturesPath + '/' + widget.message.fileName;

      _messageWidget = buildMessageMedia(widget.message, filePath, widget.message.isDownloadingFile,
          widget.message.isUploading, widget.message.uploadProgress, widget.message.stopUploadFunc);

    } else if (widget.message.messageType == 'IMAGE') {
      print('MESSAGE IMAGE');
      String filePath = widget.picturesPath + '/' + widget.message.fileName;

      _messageWidget = MessageImage(filePath, widget.message.isDownloadingFile, widget.message.isUploading,
          widget.message.uploadProgress, widget.message.stopUploadFunc);
      messageDecoration = imageDecoration(widget.message.pinned);

    } else if (widget.message.messageType == 'STICKER') {
      _messageWidget = MessageSticker(widget.message.text);
      messageDecoration = stickerBoxDecoration();

    } else if (widget.message.messageType == 'MAP_LOCATION') {
      String filePath = widget.picturesPath + '/' + widget.message.fileName;

      _messageWidget = MessageImage(
          filePath, widget.message.isDownloadingFile, widget.message.isUploading,
          widget.message.uploadProgress, widget.message.stopUploadFunc, text: widget.message.text,
          brightness: Brightness.light
      );
      messageDecoration = imageDecoration(widget.message.pinned, isPeerMessage: true);
    } else {
      _messageWidget = MessageText(widget.message.text, edited: widget.message.edited,
          brightness: Brightness.light
      );
    }

    Widget w;

    if (widget.message.replyMessage != null) {
      w = Container(
        padding: EdgeInsets.only(left: 5, top: 5), // TODO: Check reply UI
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.5),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(MESSAGE_REPLY_RADIUS),
              topRight: Radius.circular(MESSAGE_REPLY_RADIUS),
              bottomLeft: Radius.circular(MESSAGE_BUBBLE_RADIUS),
              bottomRight: Radius.circular(MESSAGE_REPLY_RADIUS)
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReplyComponent(
              isPeerMessage: true,
              message: widget.message,
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

  // Message tap handler
  resolveMessageTapHandler() {
    Function messageTapHandler = (_) {};

    if (widget.message.deleted) {
      messageTapHandler = (_) {};

    } else if (['MEDIA', 'FILE'].contains(widget.message.messageType ?? '')) {
      String filePath = widget.picturesPath + '/' + widget.message.fileName;

      messageTapHandler = (_) async {
        OpenFile.open(filePath);
      };

    } else if (widget.message.messageType == 'RECORDING') {
      if (!widget.message.isUploading) {
        String filePath = widget.picturesPath + '/' + widget.message.fileName;

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
        String filePath = widget.picturesPath + '/' + widget.message.fileName;

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
        String filePath = widget.picturesPath + '/' + widget.message.fileName;

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
}

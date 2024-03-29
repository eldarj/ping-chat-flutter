import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-deleted.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-image.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-gif.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-sticker.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-text.component.dart';
import 'package:flutterping/activity/chats/component/message/partial/message.decoration.dart';
import 'package:flutterping/activity/chats/component/message/partial/status-label.component.dart';
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

  final bool chained;

  final EdgeInsets margin;

  final String picturesPath;

  final bool isPinnedMessage;

  final Function onMessageTapDown;

  const PeerMessageComponent({Key key,
    this.message,
    this.margin,
    this.picturesPath,
    this.chained = false,
    this.isPinnedMessage = false,
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

  int recordingCurrentPositionMillis = 0;

  @override
  void initState() {
    super.initState();
    AudioPlayer.logEnabled = false;
    audioPlayer.onAudioPositionChanged.listen((Duration  p) {
      setState(() {
        recordingCurrentPositionMillis = p.inMilliseconds;
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: resolveMessageTapHandler(),
        onLongPress: widget.onMessageTapDown,
        onDoubleTap: widget.onMessageTapDown,
        child: Container(
          margin: widget.margin,
          child: Container(
            margin: EdgeInsets.only(left: 5, right: 5, top: 2.5, bottom: widget.chained || widget.isPinnedMessage ? 2.5 : 5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildMessageContent(),
                  buildPinnedLabel(),
                ]),
          ),
        ),
      ),
    );
  }

  buildPinnedLabel() {
    return widget.isPinnedMessage ? Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MessagePinnedLabel(),
      ],
    ) : Container();
  }

  buildMessageMedia(MessageDto message, filePath, isDownloadingFile, isUploading, uploadProgress, isFileValid) {
    String desc = message.fileSizeFormatted();
    String title = message.fileName;
    Color iconColor = CompanyColor.blueDark;

    IconData icon = message.messageType == 'MEDIA' ? Icons.ondemand_video : Icons.file_copy_outlined;
    Widget iconWidget = Icon(icon, color: Colors.grey.shade100, size: 20);

    int durationInMillis;
    Widget progressIndicator;

    if (message.messageType == 'RECORDING') {
      title = 'Recording';
      IconData icon = message.isRecordingPlaying ? Icons.pause : Icons.mic_none;
      if (!message.isRecordingPlaying) {
        recordingCurrentPositionMillis = 0;
      }

      if (message.recordingDuration != null) {
        var time = message.recordingDuration.split(":");
        String seconds = time[1];
        String minutes = time[0];
        durationInMillis = (int.parse(minutes) * 60 + int.parse(seconds)) * 1000;

        title += ' (${message.recordingDuration})';
      }

      progressIndicator = buildProgressIndicator(durationInMillis - 950);

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

    if (!isFileValid) {
      iconColor = Colors.grey.shade300;
      iconWidget = Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 20);
    }

    return Container(
        padding: EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: maxWidth, minWidth: maxWidth),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 10),
              child: isUploading ? Container(width: 50, height: 50, child: UploadProgressIndicator(size: 50)) :
              isDownloadingFile ? Container(height: 50, width: 50,
                  alignment: Alignment.center,
                  child: Spinner()) :
              Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: iconColor
                  ),
                  child: iconWidget
              ),
            ),
            Flexible(
              child: Container(
                alignment: Alignment.centerLeft,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          height: 15,
                          child: message.isRecordingPlaying
                              ? progressIndicator
                              : Text(title)
                      ),
                      Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ]),
              ),
            )
          ],
        ));
  }

  buildProgressIndicator(durationInMillis) {
    var maxWidth = DEVICE_MEDIA_SIZE.width - 240;

    if (durationInMillis < 100) {
      durationInMillis = 100;
    }

    var currentWidth = (recordingCurrentPositionMillis / durationInMillis) * (maxWidth);

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
            width: maxWidth, height: 0.5, color: Colors.white
        ),
        AnimatedContainer(
            duration: Duration(seconds: 1),
            width: currentWidth, height: 2, color: CompanyColor.blueDark
        ),
      ],
    );
  }

  buildMessageContent() {
    Widget _messageWidget;

    BoxDecoration _messageDecoration = peerTextBoxDecoration(
        displayBubble: widget.isPinnedMessage || !widget.chained
    );

    String filePath = widget.picturesPath + '/' + (widget.message.fileName ?? '');

    // if (widget.message.deleted) {
    //   print('MESSAGE DELETED');
    //   _messageWidget = MessageDeleted();
    //
    if (['MEDIA', 'FILE'].contains(widget.message.messageType ?? '')) {
      bool isFileValid = false;

      if (filePath != null) {
        File file = File(filePath);
        isFileValid = file.existsSync() && file.lengthSync() > 0;
      }

      _messageWidget = buildMessageMedia(widget.message, filePath, widget.message.isDownloadingFile,
          widget.message.isUploading, widget.message.uploadProgress,
          isFileValid);

    } else if (widget.message.messageType == 'RECORDING') {
      File file = File(filePath);
      bool isFileValid = file.existsSync() && file.lengthSync() > 0;

      _messageWidget = buildMessageMedia(widget.message, filePath, widget.message.isDownloadingFile,
          widget.message.isUploading, widget.message.uploadProgress,
          isFileValid);

    } else if (widget.message.messageType == 'IMAGE') {
      _messageDecoration = peerImageDecoration(widget.message.pinned);
      _messageWidget = MessageImage(
          widget.message,
          filePath, widget.message.isDownloadingFile, widget.message.isUploading,
          widget.message.uploadProgress, chained: widget.chained, isPeerMessage: true, displayStatusIcon: false,
      );

    } else if (widget.message.messageType == 'STICKER') {
      _messageDecoration = stickerBoxDecoration();
      _messageWidget = MessageSticker(stickerCode: widget.message.text, displayStatusIcon: false, message: widget.message);

    } else if (widget.message.messageType == 'GIF') {
      _messageDecoration = gifBoxDecoration(widget.message.pinned, isPeerMessage: true);
      _messageWidget = MessageGif(
          url: widget.message.text, message: widget.message, displayStatusIcon: false,
          isPeerMessage: true);

    } else if (widget.message.messageType == 'MAP_LOCATION') {
      _messageDecoration = peerImageDecoration(widget.message.pinned);
      _messageWidget = MessageImage(
          widget.message,
          filePath, widget.message.isDownloadingFile, widget.message.isUploading,
          widget.message.uploadProgress, text: widget.message.text,
          chained: widget.chained, isPeerMessage: true, displayStatusIcon: false, displayText: true,
      );
    } else {
      _messageWidget = MessageText(widget.message, displayStatusIcon: false);
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
                decoration: _messageDecoration,
                constraints: BoxConstraints(maxWidth: maxWidth), // TODO: Check max height
                child: _messageWidget)
          ]
        )
      );
    } else {
      w = Container(
          decoration: _messageDecoration,
          constraints: BoxConstraints(maxWidth: maxWidth), // TODO: Check max height
          child: _messageWidget);
    }

    return w;
  }

  // Message tap handler
  resolveMessageTapHandler() {
    Function messageTapHandler = () {};

    String filePath;

    try {
      filePath = widget.picturesPath + '/' + widget.message.fileName;
    } catch (ignored) {
      return messageTapHandler;
    }

    File file = File(filePath);
    bool isFileValid = file.existsSync() && file.lengthSync() > 0;

    if (!isFileValid) {
      return messageTapHandler;
    }

    // if (widget.message.deleted) {
    //   messageTapHandler = () {};
    //
    // } else if (['MEDIA', 'FILE'].contains(widget.message.messageType ?? '')) {
    if (['MEDIA', 'FILE'].contains(widget.message.messageType ?? '')) {
      messageTapHandler = () async {
        OpenFile.open(filePath);
      };

    } else if (widget.message.messageType == 'RECORDING') {
      if (!widget.message.isUploading) {
        messageTapHandler = () async {
          if (widget.message.isRecordingPlaying) {
            await audioPlayer.stop();
          } else {
            await audioPlayer.play(filePath, isLocal: true);
          }
        };
      }

    } else if (widget.message.messageType == 'IMAGE') {
      if (!widget.message.isUploading) {
        messageTapHandler = () async {
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
        messageTapHandler = () async {
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

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
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

class MessageComponent extends StatefulWidget {
  final MessageDto message;

  final bool chained;

  final EdgeInsets margin;

  final String picturesPath;

  final bool isPinnedMessage;

  final MessageTheme messageTheme;

  final Function onMessageTapDown;

  final bool displayTimestamp;

  const MessageComponent(
      this.messageTheme,
      {
        Key key,
        this.message,
        this.margin,
        this.picturesPath,
        this.chained = false,
        this.isPinnedMessage = false,
        this.onMessageTapDown,
        this.displayTimestamp = true
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
          margin: EdgeInsets.only(left: 5, right: 5, top: 2.5, bottom: widget.chained || widget.isPinnedMessage ? 2.5 : 5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                buildMessageContent(),
                buildPinnedLabel(),
              ]),
        ),
      ),
    );
  }

  buildPinnedLabel() {
    return widget.isPinnedMessage ? Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MessagePinnedLabel(),
      ],
    ) : Container();
  }

  buildMessageMedia(MessageDto message, filePath, isDownloadingFile, isUploading, uploadProgress, stopUploadFunc) {
    Color titleColor = Colors.grey.shade800;
    Color descColor = Colors.grey.shade500;
    Color iconColor = CompanyColor.accentGreenLight;

    Color statusLabelColor = Colors.grey.shade500;
    Color seenIconColor = Colors.green;

    if (widget.messageTheme != null) {
      titleColor = widget.messageTheme.textColor;
      descColor = widget.messageTheme.descriptionColor;
      iconColor = widget.messageTheme.iconColor;

      statusLabelColor = widget.messageTheme.statusLabelColor;
      seenIconColor = widget.messageTheme.seenIconColor;
    }


    Widget statusIcon = MessageStatusIcon(
      message.sent, message.received, message.seen,
      displayPlaceholderCheckMark: message.displayCheckMark,
      iconColor: statusLabelColor, seenIconColor: seenIconColor,
    );

    String desc = message.fileSizeFormatted();
    String title = message.fileName;

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

      progressIndicator = buildProgressIndicator(durationInMillis - 950, statusLabelColor, iconColor);

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
        padding: EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 15),
        constraints: BoxConstraints(maxWidth: maxWidth, minWidth: maxWidth),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Row(
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
                                : Text(title, style: TextStyle(color: titleColor))
                          ),
                          Text(desc, style: TextStyle(color: descColor, fontSize: 12)),
                        ]),
                  ),
                )
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 1.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      padding: EdgeInsets.only(right: 2.5),
                      margin: EdgeInsets.only(bottom: 1),
                      child: statusIcon),
                  MessageTimestampLabel(message.sentTimestamp, statusLabelColor, edited: message.edited)
                ],
              ),
            )
          ],
        ));
  }

  buildProgressIndicator(durationInMillis, loaderColor, progressColor) {
    var maxWidth = DEVICE_MEDIA_SIZE.width - 240;
    var currentWidth = (recordingCurrentPositionMillis / durationInMillis) * (maxWidth);

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
            width: maxWidth, height: 0.5, color: loaderColor
        ),
        AnimatedContainer(
            duration: Duration(seconds: 1),
            width: currentWidth, height: 2, color: progressColor
        ),
      ],
    );
  }

  buildMessageContent() {
    Widget _messageWidget;

    BoxDecoration _messageDecoration = myTextBoxDecoration(
        myMessageBackground: widget.messageTheme.bubbleColor,
        displayBubble: widget.isPinnedMessage || !widget.chained
    );

    // if (widget.message.deleted) {
    //   print('MESSAGE DELETED');
    //   _messageWidget = MessageDeleted();
    //
    // } else if (['MEDIA', 'FILE'].contains(widget.message.messageType??'')) {
    if (['MEDIA', 'FILE'].contains(widget.message.messageType??'')) {
      String filePath = widget.message.filePath;

      _messageWidget = buildMessageMedia(widget.message, filePath, widget.message.isDownloadingFile,
          widget.message.isUploading, widget.message.uploadProgress, widget.message.stopUploadFunc);

    } else if (widget.message.messageType == 'RECORDING') {
      String filePath = widget.message.filePath;

      _messageWidget = buildMessageMedia(widget.message, filePath, widget.message.isDownloadingFile,
          widget.message.isUploading, widget.message.uploadProgress, widget.message.stopUploadFunc);

    } else if (widget.message.messageType == 'IMAGE') {
      String filePath = widget.message.filePath;

      _messageDecoration = imageDecoration(widget.message.pinned, widget.messageTheme.bubbleColor);
      _messageWidget = MessageImage(widget.message, filePath, widget.message.isDownloadingFile, widget.message.isUploading,
          widget.message.uploadProgress, widget.message.stopUploadFunc, chained: widget.chained, messageTheme: widget.messageTheme);

    } else if (widget.message.messageType == 'STICKER') {
      _messageDecoration = stickerBoxDecoration();
      _messageWidget = MessageSticker(stickerCode: widget.message.text, message: widget.message,
          messageTheme: widget.messageTheme, displayTimestamp: widget.displayTimestamp);

    } else if (widget.message.messageType == 'GIF') {
      _messageDecoration = gifBoxDecoration(widget.message.pinned);
      _messageWidget = MessageGif(
          url: widget.message.text, message: widget.message, messageTheme: widget.messageTheme,
      );

    } else if (widget.message.messageType == 'MAP_LOCATION') {
      String filePath = widget.message.filePath;

      _messageDecoration = imageDecoration(widget.message.pinned, widget.messageTheme.bubbleColor);
      _messageWidget = MessageImage(
          widget.message,
          filePath, widget.message.isDownloadingFile, widget.message.isUploading,
          widget.message.uploadProgress, widget.message.stopUploadFunc, text: widget.message.text,
          textColor: widget.messageTheme.textColor, chained: widget.chained,
          messageTheme: widget.messageTheme, displayText: true,
      );
    } else {
      _messageWidget = MessageText(widget.message, messageTheme: widget.messageTheme);
    }

    Widget w;

    if (widget.message.replyMessage != null) {
      w = Column(crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ReplyComponent(
              isPeerMessage: false,
              message: widget.message,
              picturesPath: widget.picturesPath,
            ),
            Container(
                decoration: _messageDecoration,
                constraints: BoxConstraints(maxWidth: maxWidth),
                // TODO: Check max height
                child: _messageWidget)
          ]
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
    Function messageTapHandler = (_) {};

    // if (widget.message.deleted) {
    //   messageTapHandler = (_) {};
    //
    // } else if (['MEDIA', 'FILE'].contains(widget.message.messageType ?? '')) {
    if (['MEDIA', 'FILE'].contains(widget.message.messageType ?? '')) {
      String filePath = widget.message.filePath;

      messageTapHandler = (_) async {
        OpenFile.open(filePath);
      };

    } else if (widget.message.messageType == 'RECORDING') {
      if (!widget.message.isUploading) {
        String filePath = widget.message.filePath;

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
        String filePath = widget.message.filePath;

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
        String filePath = widget.message.filePath;

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

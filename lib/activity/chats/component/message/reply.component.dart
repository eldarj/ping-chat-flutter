import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-content.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-decoration.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/reply-dto.model.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/duration.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:open_file/open_file.dart';

class ReplyComponent extends StatefulWidget {
  final MessageDto message;

  final String picturesPath;

  final bool isPeerMessage;

  const ReplyComponent({Key key,
    this.message,
    this.isPeerMessage,
    this.picturesPath,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => ReplyComponentState();
}

class ReplyComponentState extends State<ReplyComponent> {
  ScaffoldState scaffold;

  double maxWidth = DEVICE_MEDIA_SIZE.width - 200;

  AudioPlayer audioPlayer = AudioPlayer();

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
        widget.message.replyMessage.isRecordingPlaying = audioPlayerState == AudioPlayerState.PLAYING;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    scaffold = Scaffold.of(context);
    return InkWell(
      onTap: resolveMessageTapHandler(),
      child: Container(
        margin: EdgeInsets.only(bottom: 2.5),
        padding: EdgeInsets.only(bottom: 5, top: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(MESSAGE_REPLY_RADIUS),
            topRight: Radius.circular(MESSAGE_REPLY_RADIUS),
            bottomLeft: Radius.circular(widget.isPeerMessage ? 0 : MESSAGE_REPLY_RADIUS),
            bottomRight: Radius.circular(widget.isPeerMessage ? MESSAGE_REPLY_RADIUS : 0)
          ),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
                child: Text('REPLIED TO', style: TextStyle(
                    color: CompanyColor.blueDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4
                )),
              ),
              buildMessageContent(),
            ]
        ),
      ),
    );
  }

  buildMessageContent() {
    Widget _messageWidget;

    var padding = EdgeInsets.only(bottom: 5, left: 10, right: 10);

    if (widget.message.replyMessage.messageType == 'DELETED') {
      print('MESSAGE DELETED');
      _messageWidget = MessageDeleted();

    } else if (['MEDIA', 'FILE'].contains(widget.message.replyMessage.messageType??'')) {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.replyMessage.fileName
          : widget.message.replyMessage.filePath;

      _messageWidget = buildMessageMedia(widget.message.replyMessage, filePath, false,
          false, 0, () {});

    } else if (widget.message.replyMessage.messageType == 'RECORDING') {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.replyMessage.fileName
          : widget.message.replyMessage.filePath;

      _messageWidget = buildMessageMedia(widget.message.replyMessage, filePath, false,
          false, widget.message.uploadProgress, () {});

    } else if (widget.message.replyMessage.messageType == 'IMAGE') {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.replyMessage.fileName
          : widget.message.replyMessage.filePath;

      _messageWidget = Opacity(
        opacity: 0.8,
        child: Container(
          constraints: BoxConstraints(maxWidth: 120),
          child: ClipRRect(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(widget.isPeerMessage ? 0 : 10),
                  bottomRight: Radius.circular(widget.isPeerMessage ? 10 : 0)
              ),
              child: MessageImage(filePath, false, false, 0.0, () {},
                  isPeerMessage: widget.isPeerMessage)),
        ),
      );
      padding = EdgeInsets.all(0);

    } else if (widget.message.replyMessage.messageType == 'MAP_LOCATION') {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.replyMessage.fileName
          : widget.message.replyMessage.filePath;

      padding = EdgeInsets.all(0);
      _messageWidget = Opacity(
        opacity: 0.8,
        child: Container(
          constraints: BoxConstraints(maxWidth: 120),
          child: MessageImage(filePath, false, false, 0.0, () {},
              text: widget.message.replyMessage.text, isPeerMessage: widget.isPeerMessage),
        ),
      );

    } else if (widget.message.replyMessage.messageType == 'STICKER') {
      _messageWidget = Opacity(
        opacity: 0.8,
        child: Container(
            width: 75, height: 50,
            child: MessageSticker(stickerCode: widget.message.replyMessage.text, displayStatusIcon: false)),
      );

    } else if (widget.message.replyMessage.messageType == 'GIF') {
      _messageWidget = Opacity(
        opacity: 0.8,
        child: Container(
            constraints: BoxConstraints(maxWidth: 80),
            child: ClipRRect(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(widget.isPeerMessage ? 0 : 10),
                    bottomRight: Radius.circular(widget.isPeerMessage ? 10 : 0)
                ),
                child: MessageGif(url: widget.message.replyMessage.text, displayStatusIcon: false))),
      );

    } else {
      _messageWidget = Text(widget.message.replyMessage.text, style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 12,
      ));
    }

    return Container(
        padding: padding,
        constraints: BoxConstraints(maxWidth: maxWidth), // TODO: Check max height
        child: _messageWidget);
  }

  buildMessageMedia(ReplyDto message, filePath, isDownloadingFile, isUploading, uploadProgress, stopUploadFunc) {
    String desc = message.fileSizeFormatted();
    String title = message.fileName;

    Widget iconWidget = Icon(
        message.messageType == 'MEDIA' ? Icons.ondemand_video : Icons.file_copy_outlined,
        color: Colors.grey.shade100,
        size: 15);

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
              margin: EdgeInsets.only(bottom: message.isRecordingPlaying ? 7.5 : 0),
              child: Icon(icon, color: Colors.grey.shade100, size: 15)),
          Container(
              margin: EdgeInsets.only(top: message.isRecordingPlaying ? 7.5 : 0),
              child: Text(recordingCurrentPosition, style: TextStyle(
                  fontSize: 8,
                  color: message.isRecordingPlaying ? Colors.grey.shade100 : Colors.transparent))
          ),
        ],
      );
    }

    return Container(
        constraints: BoxConstraints(maxWidth: maxWidth, minWidth: maxWidth),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 7.5),
              child: isUploading ? GestureDetector(onTap: stopUploadFunc, child: Container(
                  width: 25, height: 25, child: UploadProgressIndicator(size: 25, progress: uploadProgress))) :
              isDownloadingFile ? Container(height: 25, width: 25,
                  alignment: Alignment.center,
                  child: Spinner()) :
              Container(
                  width: 25, height: 25,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.grey.shade400
                  ),
                  child: iconWidget
              ),
            ),
            Container(
              width: maxWidth - 70,
              alignment: Alignment.centerLeft,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    Text(desc, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                  ]),
            )
          ],
        ));
  }


  // Message tap handler
  resolveMessageTapHandler() {
    Function messageTapHandler = () {};

    if (['MEDIA', 'FILE'].contains(widget.message.replyMessage.messageType ?? '')) {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.replyMessage.fileName
          : widget.message.replyMessage.filePath;

      messageTapHandler = () async {
        OpenFile.open(filePath);
      };

    } else if (widget.message.replyMessage.messageType == 'RECORDING') {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.replyMessage.fileName
          : widget.message.replyMessage.filePath;

      messageTapHandler = () async {
        if (widget.message.replyMessage.isRecordingPlaying) {
          await audioPlayer.stop();
        } else {
          await audioPlayer.play(filePath, isLocal: true);
        }
      };

    } else if (widget.message.replyMessage.messageType == 'IMAGE') {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.replyMessage.fileName
          : widget.message.replyMessage.filePath;

      messageTapHandler = () async {
        NavigatorUtil.push(context,
            ImageViewerActivity(
                reply: widget.message.replyMessage,
                timestamp: widget.message.replyMessage.sentTimestamp,
                file: File(filePath)));
      };

    } else if (widget.message.replyMessage.messageType == 'MAP_LOCATION') {
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.replyMessage.fileName
          : widget.message.replyMessage.filePath;

      messageTapHandler = () async {
        NavigatorUtil.push(context,
            ImageViewerActivity(
                reply: widget.message.replyMessage,
                timestamp: widget.message.replyMessage.sentTimestamp,
                file: File(filePath))
        );
      };
    }

    return messageTapHandler;
  }
}

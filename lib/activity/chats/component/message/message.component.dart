import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-content.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-decoration.dart';
import 'package:flutterping/activity/chats/component/message/partial/message-status.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/loader/upload-progress-indicator.element.dart';
import 'package:flutterping/util/extension/duration.extension.dart';
import 'package:flutterping/shared/var/global.var.dart';
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

  const MessageComponent({Key key,
    this.message,
    this.isPeerMessage,
    this.displayTimestamp,
    this.margin,
    this.picturesPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MessageComponentState();
}

class MessageComponentState extends State<MessageComponent> {
  ScaffoldState scaffold;

  double maxWidth = DEVICE_MEDIA_SIZE.width - 150;

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

    audioPlayer.onPlayerStateChanged.listen((AudioPlayerState s) {
      setState(() {
        widget.message.isRecordingPlaying = s == AudioPlayerState.PLAYING;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    scaffold = Scaffold.of(context);

    return GestureDetector(
      onTapUp: resolveMessageTapHandler(),
      onLongPressEnd: (details) {
        onMessageTapDown(details, widget.message, widget.isPeerMessage, [
          PopupMenuItem(value: 'DELETE', child: Text("Delete")),
        ]);
      },
      child: Container(
        margin: widget.margin,
        child: Container(
          margin: EdgeInsets.only(left: 5, right: 5, bottom: widget.displayTimestamp ? 20 : 2.5),
          child: Column(crossAxisAlignment: widget.isPeerMessage ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                buildMessageContent(),
                MessageStatusRow(widget.isPeerMessage,
                    widget.message.sentTimestamp,
                    widget.message.displayCheckMark,
                    widget.displayTimestamp,
                    widget.message.sent,
                    widget.message.received,
                    widget.message.seen),
              ]),
        ),
      ),
    );
  }

  buildMessageMedia(MessageDto message, filePath, isDownloadingFile, isUploading, uploadProgress, stopUploadFunc) {
    print(message.messageType);
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
        children: <Widget>[
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

    BoxDecoration messageDecoration = widget.isPeerMessage ? peerTextBoxDecoration() : myTextBoxDecoration();

    if (widget.message.deleted) {
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
      String filePath = widget.isPeerMessage
          ? widget.picturesPath + '/' + widget.message.fileName
          : widget.message.filePath;

      _messageWidget = MessageImage(filePath, widget.message.isDownloadingFile, widget.message.isUploading,
          widget.message.uploadProgress, widget.message.stopUploadFunc);
      messageDecoration = imageDecoration();

    } else if (widget.message.messageType == 'STICKER') {
      _messageWidget = MessageSticker(widget.message.text);
      messageDecoration = stickerBoxDecoration();

    } else {
      _messageWidget = MessageText(widget.message.text);
    }

    return Container(
        decoration: messageDecoration,
        constraints: BoxConstraints(maxWidth: maxWidth), // TODO: Check max height
        child: _messageWidget);
  }

  resolveMessageTapHandler() {
    Function messageTapHandler = (_) {};

    if (widget.message.deleted) {
      messageTapHandler = (_) {};
    } else if (['MEDIA', 'FILE'].contains(widget.message.messageType??'')) {
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

    } else if (widget.message.messageType == 'STICKER') {
      messageTapHandler = (details) {
        onMessageTapDown(details, widget.message, widget.isPeerMessage, [
          PopupMenuItem(value: 'DELETE', child: Text("Delete")),
        ]);
      };

    } else {
      messageTapHandler = (details) {
        onMessageTapDown(details, widget.message, widget.isPeerMessage, [
          PopupMenuItem(value: 'DELETE', child: Text("Delete")),
        ]);
      };
    }

    return messageTapHandler;
  }

  onMessageTapDown(details, MessageDto message, bool isPeerMessage, items) async {
    FocusScope.of(context).requestFocus(new FocusNode());
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(isPeerMessage ? 0 : 1, details.globalPosition.dy, 0, 0),
      elevation: 8.0,
      items: items,
    ).then((value) {
      if (value == 'EDIT') {

      } else if (value == 'DELETE') {
        doDeleteMessage(message).then(onDeleteMessageSuccess, onError: onDeleteMessageError);
      }
    });
  }

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
}

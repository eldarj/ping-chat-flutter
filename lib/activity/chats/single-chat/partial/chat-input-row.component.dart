
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/service/messaging/message-sending.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/util/other/file-type-resolver.util.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:tus_client/tus_client.dart';
import 'package:flutterping/util/extension/duration.extension.dart';

class SingleChatInputRow extends StatefulWidget {
  final int userId;
  final int peerId;
  final int userSentNodeId;
  final String picturesPath;

  final MessageSendingService messageSendingService;
  final Function(MessageDto, double) onProgress;

  final Function onOpenStickerBar;
  final bool displayStickers;

  final Function onOpenShareBottomSheet;
  final bool displaySendButton;

  final TextEditingController inputTextController;
  final FocusNode inputTextFocusNode;

  final Function doSendMessage;

  const SingleChatInputRow({Key key, this.messageSendingService, this.onProgress, this.onOpenStickerBar,
    this.displayStickers, this.onOpenShareBottomSheet, this.displaySendButton, this.inputTextController,
    this.inputTextFocusNode, this.doSendMessage, this.userId, this.peerId, this.userSentNodeId, this.picturesPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SingleChatInputRowState();
}

class SingleChatInputRowState extends State<SingleChatInputRow> with TickerProviderStateMixin {
  bool isRecording = false;
  var recorder;

  AnimationController _fadeInAnimationController;
  Animation<double> _fadeInAnimation;

  AnimationController _blinkingAnimationController;

  StopWatchTimer _stopWatchTimer;

  String recordingDuration = '00:00';

  @override
  initState() {
    super.initState();

    _blinkingAnimationController = new AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _blinkingAnimationController.repeat(reverse: true);

    _fadeInAnimationController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
        value: 0,
        lowerBound: 0,
        upperBound: 1
    );
    _fadeInAnimation = CurvedAnimation(parent: _fadeInAnimationController, curve: Curves.fastOutSlowIn);

    _stopWatchTimer = StopWatchTimer(
      onChangeRawSecond: (value) {
        setState(() {
          recordingDuration = Duration(seconds: value).format();
        });
      },
    );
  }


  @override
  void dispose() {
    _stopWatchTimer.dispose();
    _blinkingAnimationController.dispose();
    _fadeInAnimationController.dispose();
    super.dispose();
  }

  cancelRecording() async {
    setState(() {
      isRecording = false;
    });
    _fadeInAnimationController.animateBack(0);
    _stopWatchTimer.onExecute.add(StopWatchExecute.reset);
    await recorder.stop();
  }

  startRecording(context) async {
    setState(() {
      isRecording = true;
    });
    _fadeInAnimationController.forward();
    _stopWatchTimer.onExecute.add(StopWatchExecute.start);

    DateFormat formatter = DateFormat('yyyy-MM-dd-Hms');

    recorder = FlutterAudioRecorder(widget.picturesPath + "/recording-" + formatter.format(DateTime.now()) + ".mp4"); // .wav .aac .m4a
    await recorder.initialized;
    await recorder.start();
  }

  sendRecording() async {
    setState(() {
      isRecording = false;
    });
    _fadeInAnimationController.animateBack(0);

    var fileDuration = recordingDuration;
    _stopWatchTimer.onExecute.add(StopWatchExecute.reset);

    var result = await recorder.stop();
    File file = File(result.path);

    var fileName = basename(file.path);
    var fileType = 'RECORDING';
    var fileSize = file.lengthSync();
    var fileUrl = Uri.parse(API_BASE_URL + '/files/uploads/' + fileName).toString();

    var userToken = await UserService.getToken();

    DSNodeDto dsNodeDto = new DSNodeDto();
    dsNodeDto.ownerId = widget.userId;
    dsNodeDto.receiverId = widget.peerId;
    dsNodeDto.parentDirectoryNodeId = widget.userSentNodeId;
    dsNodeDto.nodeName = fileName;
    dsNodeDto.fileUrl = fileUrl;
    dsNodeDto.fileSizeBytes = fileSize;
    dsNodeDto.pathOnSourceDevice = file.path;

    TusClient fileUploadClient = TusClient(
      Uri.parse(API_BASE_URL + DATA_SPACE_ENDPOINT),
      file,
      store: TusMemoryStore(),
      headers: {'Authorization': 'Bearer $userToken'},
      metadata: {'dsNodeEncoded': json.encode(dsNodeDto)},
    );

    MessageDto message = widget.messageSendingService.addPreparedFile(fileName, file.path,
        fileUrl, fileSize, fileType, recordingDuration: fileDuration);

    message.stopUploadFunc = () async {
      message.deleted = true;
      message.isUploading = false;
      await Future.delayed(Duration(seconds: 2));
      fileUploadClient.delete();
    };

    widget.onProgress(message, 10);
    await Future.delayed(Duration(milliseconds: 500));
    widget.onProgress(message, 30);
    await Future.delayed(Duration(milliseconds: 500));

    try {
      await fileUploadClient.upload(
        onComplete: (response) async {
          var nodeId = response.headers['x-nodeid'];
          message.isUploading = false;
          message.nodeId = int.parse(nodeId);
          await Future.delayed(Duration(milliseconds: 250));
          widget.messageSendingService.sendFile(message);
        },
        onProgress: (progress) {
          if (widget.onProgress != null) {
            if (progress > 30) {
              widget.onProgress(message, progress);
            }
          }
        },
      );
    } catch (exception) {
      print('Error uploading file');
      print(exception); //TODO: Handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [Shadows.topShadow()],
        ),
        width: DEVICE_MEDIA_SIZE.width, height: 55,
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: <Widget>[
            Container(
              child: Row(children: [
                Container(
                  child: GestureDetector(
                    onTap: widget.onOpenStickerBar,
                    child: Container(
                      height: 35, width: 50,
                      child: !widget.displayStickers
                          ? Image.asset('static/graphic/icon/sticker.png', color: CompanyColor.blueDark)
                          : Icon(Icons.keyboard_arrow_down, color: CompanyColor.blueDark),
                    ),
                  ),
                ),
                Container(constraints: BoxConstraints(maxWidth: DEVICE_MEDIA_SIZE.width - 210),
                  child: TextField(
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 2,
                    onSubmitted: (value) {
                      widget.inputTextController.text += "asd";
                    },
                    style: TextStyle(fontSize: 15.0),
                    controller: widget.inputTextController,
                    focusNode: widget.inputTextFocusNode,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Vaša poruka...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                Container(
                  child: IconButton(
                    icon: Icon(Icons.attachment),
                    onPressed: widget.onOpenShareBottomSheet,
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
              ]),
            ),
            widget.displaySendButton ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                    margin: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
                    height: 45, width: 45,
                    decoration: BoxDecoration(
                      color: CompanyColor.blueDark,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Container(
                      margin: EdgeInsets.only(left: 2.5),
                      child: IconButton(
                        icon: Icon(Icons.send),
                        iconSize: 26,
                        onPressed: widget.doSendMessage,
                        color: Colors.white,
                      ),
                    )            ),
              ],
            ) : buildRecordingRow()
          ],
        ));
  }

  buildRecordingRow() {
    return Container(
      width: DEVICE_MEDIA_SIZE.width,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: <Widget>[
          IgnorePointer(
            ignoring: !isRecording,
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Container(
                height: 55,
                color: Colors.white,
                padding: EdgeInsets.only(left: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(
                        margin: EdgeInsets.only(right: 10),
                        child: FadeTransition(
                          opacity: _blinkingAnimationController,
                          child: Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
                        )),
                    Text(recordingDuration, style: TextStyle(fontSize: 14))
                  ]),
                  Container(
                    margin: EdgeInsets.only(right: 100),
                    child: FlatButton(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        color: Colors.grey.shade200,
                        onPressed: cancelRecording,
                        child: Text('Cancel', style: TextStyle(fontSize: 14, color: Colors.grey.shade500))
                    ),
                  ),
                ]),
              ),
            ),
          ),
          buildSendButton()
        ],
      ),
    );
  }

  buildSendButton() {
    return AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        margin: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
        height: 45, width: 45,
        decoration: BoxDecoration(
            color: isRecording ? Colors.white : CompanyColor.blueDark,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: isRecording ? Colors.white : CompanyColor.blueDark,
                style: BorderStyle.solid, width: isRecording ? 2 : 0),
            boxShadow: [
              BoxShadow(
                  color: isRecording ? Color.fromRGBO(255, 0, 0, 0.2) : CompanyColor.bluePrimary,
                  blurRadius: 0, spreadRadius: isRecording ? 40 : 0)
            ]
        ),
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (isRecording) {
                sendRecording();
              } else {
                startRecording(context);
              }
            });
          },
          child: Container(
            margin: EdgeInsets.only(left: isRecording ? 2.5 : 0),
            child: Icon(isRecording ? Icons.send : Icons.mic,
                size: isRecording ? 26 : 30,
                color: isRecording ? CompanyColor.blueDark : Colors.white),
          ),
        ));
  }
}
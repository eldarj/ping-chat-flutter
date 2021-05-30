import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/messaging/message-sending.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/duration.extension.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:tus_client/tus_client.dart';

class SingleChatInputRow extends StatefulWidget {
  final int userId;
  final int peerId;
  final int userSentNodeId;
  final String picturesPath;
  final String myContactName;
  final String contactPhoneNumber;

  final MessageSendingService messageSendingService;
  final Function(MessageDto, double) onProgress;

  final Function onOpenStickerBar;
  final bool displayStickers;
  final bool displayGifs;

  final Function onOpenShareBottomSheet;
  final bool displaySendButton;

  final TextEditingController inputTextController;
  final FocusNode inputTextFocusNode;

  final Function doSendMessage;

  final bool isEditing;

  final Function onCancelEdit;

  final Function onSubmitEdit;

  final bool isReplying;

  final Widget replyWidget;

  final Function onCancelReply;

  final Function onSubmitReply;

  final Function onOpenGifPicker;

  const SingleChatInputRow({Key key, this.messageSendingService, this.onProgress, this.onOpenStickerBar,
    this.displayStickers, this.onOpenShareBottomSheet, this.displaySendButton, this.inputTextController,
    this.inputTextFocusNode, this.doSendMessage, this.userId, this.peerId, this.userSentNodeId,
    this.picturesPath, this.myContactName, this.onOpenGifPicker, this.displayGifs,
    this.isEditing, this.onCancelEdit, this.onSubmitEdit, this.contactPhoneNumber,
    this.isReplying, this.replyWidget, this.onCancelReply, this.onSubmitReply,
  }) : super(key: key);

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

  bool sendingTypingEvent = false;

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
    dsNodeDto.nodeType = fileType;
    dsNodeDto.description = widget.myContactName;
    dsNodeDto.recordingDuration = fileDuration;
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

    // message.stopUploadFunc = () async {
    //   message.stoppedUpload = true; // TODO: Handle stop upload
    //   message.isUploading = false;
    //   messageDeletedPublisher.emitMessageDeleted(message);
    //   await Future.delayed(Duration(seconds: 2));
    //   fileUploadClient.delete();
    // };

    widget.onProgress(message, 10);
    await Future.delayed(Duration(milliseconds: 500));
    widget.onProgress(message, 20);
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
    Widget w;

    if (false) { // TODO: Fix
      w = Container();
    } else {
      w = Center(
        child: Column(
          children: [
            buildTopDetailsSection(),
            Container(
                constraints: BoxConstraints(
                  maxHeight: 100, minHeight: 90
                ),
                width: DEVICE_MEDIA_SIZE.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [Shadows.topShadow()],
                ),
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                              minHeight: 45,
                              maxHeight: 55,
                              maxWidth: DEVICE_MEDIA_SIZE.width - 65), // TODO: Dynamic width
                          padding: EdgeInsets.only(left: 15),
                          child: TextField(
                            cursorHeight: 18,
                            textAlignVertical: TextAlignVertical.top,
                            textInputAction: TextInputAction.newline,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 2,
                            onChanged: (_) {
                              if (!sendingTypingEvent) {
                                sendingTypingEvent = true;
                                sendTypingEvent(widget.contactPhoneNumber, true);
                                Future.delayed(Duration(seconds: 2), () { sendingTypingEvent = false; });
                              }
                            },
                            onSubmitted: (value) {
                              widget.inputTextController.text += "asd"; //TODO: Remove
                            },
                            style: TextStyle(fontSize: 15.0),
                            controller: widget.inputTextController,
                            focusNode: widget.inputTextFocusNode,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Type a message',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        Container(
                          height: 45,
                          child: Row(
                              children: [
                                buildActionButton(
                                    icon: Icons.sentiment_very_satisfied,
                                    onPressed: widget.onOpenStickerBar
                                ),
                                buildActionButton(
                                    widget: Container(
                                        child: Icon(Icons.gif_outlined, color: Colors.grey.shade500)),
                                    onPressed: widget.onOpenGifPicker
                                ),
                                buildActionButton(
                                    icon: Icons.attachment_sharp,
                                    onPressed: widget.onOpenShareBottomSheet
                                ),
                              ]
                          ),
                        )
                      ],
                    ),
                    widget.isEditing
                        ? buildEditButton() : widget.isReplying
                        ? buildReplyButton() : widget.displaySendButton
                        ? buildSendButton()
                        : buildRecordingRow()
                  ],
                )),
          ],
        ),
      );
    }

    return w;
  }

  buildActionButton({ icon, widget, onPressed }) {
    return Container(
      width: 60,
      child: Material(
        color: Colors.white,
        child: IconButton(
          iconSize: 30,
          icon: icon != null
              ? Icon(icon, color: Colors.grey.shade500, size: 21)
              : widget,
          onPressed: onPressed,
          color: CompanyColor.blueDark,
        ),
      ),
    );
  }

  buildEditButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
            margin: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
            height: 45, width: 45,
            decoration: BoxDecoration(
              color: CompanyColor.blueDark,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Container(
              child: IconButton(
                icon: Icon(Icons.check),
                iconSize: 26,
                onPressed: widget.onSubmitEdit,
                color: Colors.white,
              ),
            )
        ),
      ],
    );
  }

  buildReplyButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
            margin: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
            height: 45, width: 45,
            decoration: BoxDecoration(
              color: CompanyColor.blueDark,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Container(
              child: IconButton(
                icon: Icon(Icons.check),
                iconSize: 26,
                onPressed: widget.onSubmitReply,
                color: Colors.white,
              ),
            )
        ),
      ],
    );
  }

  buildRecordingRow() {
    return Container(
      width: DEVICE_MEDIA_SIZE.width,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          IgnorePointer(
            ignoring: !isRecording,
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Container(
                height: 85,
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
          buildSendRecordingButton()
        ],
      ),
    );
  }

  buildSendRecordingButton() {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isRecording) {
              sendRecording();
            } else {
              startRecording(context);
            }
          });
        },
        onLongPress: () {
          if (!isRecording) {
            startRecording(context);
          }
        },
        child: Container(
          height: 85,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  margin: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
                  height: 45, width: 45,
                  constraints: BoxConstraints(
                    maxHeight: 45, maxWidth: 45
                  ),
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
                  child: Container(
                    margin: EdgeInsets.only(left: isRecording ? 2.5 : 0),
                    child: Icon(isRecording ? Icons.send : Icons.mic,
                        size: isRecording ? 26 : 30,
                        color: isRecording ? CompanyColor.blueDark : Colors.white),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  buildSendButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              widget.doSendMessage.call();
            },
            child: Container(
                height: 85,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      margin: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
                      constraints: BoxConstraints(
                          maxHeight: 45, maxWidth: 45
                      ),
                      decoration: BoxDecoration(
                        color: CompanyColor.blueDark,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Container(
                        margin: EdgeInsets.only(left: 2.5),
                        child: Icon(Icons.send, size: 26, color: Colors.white),
                      ),
                    ),
                  ],
                )
            ),
          ),
        ),
      ],
    );
  }

  buildTopDetailsSection() {
    Widget w;

    if (widget.isEditing) {
      w = Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: Colors.grey.shade50,
              boxShadow: [Shadows.topShadow()]
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                child: Material(
                    color: Colors.transparent,
                    child: buildCancelButton()
                ),
              ),
              Container(
                width: DEVICE_MEDIA_SIZE.width - 80,
                child: Text('EDIT MESSAGE', style: TextStyle(
                    color: CompanyColor.blueDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4
                )),
              ),
            ],
          )
      );
    } else if (widget.isReplying) {
      w = Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            boxShadow: [Shadows.topShadow()]
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                child: Material(
                    color: Colors.transparent,
                    child: buildCancelButton()
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REPLY', style: TextStyle(
                      color: CompanyColor.blueDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4
                  )),
                  widget.replyWidget
                ],
              ),
            ],
          )
      );
    } else {
     w = Container();
    }

    return w;
  }

  buildCancelButton() {
    Widget w = Container();

    if (widget.isEditing) {
      w = IconButton(
          icon: Icon(Icons.close),
          color: CompanyColor.blueDark,
          onPressed: () {
            widget.onCancelEdit.call();
          }
      );
    } else if (widget.isReplying) {
      w = IconButton(
          icon: Icon(Icons.close),
          color: CompanyColor.blueDark,
          onPressed: () {
            widget.onCancelReply.call();
          }
      );
    }

    return w;
  }
}

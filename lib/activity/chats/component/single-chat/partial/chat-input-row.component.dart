
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/service/messaging/message-sending.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/util/other/file-type-resolver.util.dart';
import 'package:path/path.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:tus_client/tus_client.dart';

class SingleChatInputRow extends StatefulWidget {
  final MessageSendingService messageSendingService;
  final Function(MessageDto, double) onProgress;

  final Function onOpenStickerBar;
  final bool displayStickers;

  final Function onOpenShareBottomSheet;
  final bool displaySendButton;

  final TextEditingController inputTextController;
  final FocusNode inputTextFocusNode;

  final Function doSendMessage;

  const SingleChatInputRow({Key key, this.messageSendingService, this.onProgress, this.onOpenStickerBar, this.displayStickers, this.onOpenShareBottomSheet, this.displaySendButton, this.inputTextController, this.inputTextFocusNode, this.doSendMessage}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SingleChatInputRowState();
}

class SingleChatInputRowState extends State<SingleChatInputRow> {
  var recorder;
  bool isRecording = false;

  startRecording(context) async {
    var storageIOService = new StorageIOService();
    var s = await storageIOService.getPicturesPath();
    var d = DateTime.now();
    var path = s.toString() + "/recording-" + d.year.toString()
        + d.month.toString()
        + d.day.toString()
        + d.hour.toString()
        + d.minute.toString()
        + d.second.toString() + ".mp4";
    //
    if (!isRecording) {
      recorder = FlutterAudioRecorder(path); // .wav .aac .m4a
      await recorder.initialized;
      await recorder.start();
      isRecording = true;
      print('STARTED RECORDING');
    } else {
      var recording = await recorder.current(channel: 0);
      var result = await recorder.stop();
      File file = File(result.path);

      var fileName = basename(file.path);
      var fileType = FileTypeResolverUtil.resolve(extension(fileName));
      var fileSize = file.lengthSync();

      var userToken = await UserService.getToken();

      TusClient fileUploadClient = TusClient(
        Uri.parse(API_BASE_URL + DATA_SPACE_ENDPOINT),
        file,
        store: TusMemoryStore(),
        headers: {'Authorization': 'Bearer $userToken'},
      );

      // ADD FILE LOCALLY
      MessageDto message = widget.messageSendingService.addPreparedFile(fileName, file.path,
          Uri.parse(API_BASE_URL + '/files/uploads/' + fileName).toString(), fileSize, fileType);

      message.stopUploadFunc = () async {
        setState(() {
          message.deleted = true;
          message.isUploading = false;
        });
        await Future.delayed(Duration(seconds: 2));
        fileUploadClient.delete();
      };
      // widget.onPicked(fileUploadClient, fileName, file.path, Uri.parse(API_BASE_URL + '/files/uploads/' + fileName));

      widget.onProgress(message, 10);
      await Future.delayed(Duration(milliseconds: 500));
      widget.onProgress(message, 30);
      await Future.delayed(Duration(milliseconds: 500));

      // HANDLE ON COMPLETE ETC HERE
      try {
        await fileUploadClient.upload(
          onComplete: (response) async {
            await Future.delayed(Duration(milliseconds: 250));
            message.isUploading = false;
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
      print('STOPPED RECORDING');
    }
  }

  // stopRecording(LongPressEndDetails longPressEndDetails) async {
  //   bool isRecording = await AudioRecorder.isRecording;
  //   if (isRecording) {
  //     Recording recording = await AudioRecorder.stop();
  //     print("Path : ${recording.path},  Format : ${recording.audioOutputFormat},  Duration : ${recording.duration},  Extension : ${recording.extension},");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [Shadows.topShadow()],
        ),
        width: DEVICE_MEDIA_SIZE.width,
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
          widget.displaySendButton ? Container(
              margin: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
              height: 45, width: 45,
              decoration: BoxDecoration(
                color: CompanyColor.blueDark,
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                icon: Icon(Icons.send),
                iconSize: 18,
                onPressed: widget.doSendMessage,
                color: Colors.white,
              )
          ) :
          Container(
              margin: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
              height: 45, width: 45,
              decoration: BoxDecoration(
                color: CompanyColor.blueDark,
                borderRadius: BorderRadius.circular(50),
              ),
              child: GestureDetector(
                onTap: () => startRecording(context),
                child: Icon(Icons.mic, size: 18, color: Colors.white),
              )),
        ]));
  }
}

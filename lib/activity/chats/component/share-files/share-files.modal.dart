import 'dart:io';

import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/message-sending.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:tus_client/tus_client.dart';

import '../../../../shared/modal/floating-modal.dart';

class ShareFilesModal extends StatefulWidget {
  final Function(MessageDto, double) onProgress;

  final MessageSendingService messageSendingService;

  const ShareFilesModal({Key key, this.messageSendingService, this.onProgress}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShareFilesModalState();
}

class ShareFilesModalState extends BaseState<ShareFilesModal> {
  File file;

  openFilePicker() async {
    Navigator.of(getScaffoldContext()).pop();
    file = await FilePicker.getFile(onFileLoading: (status) {});

    var fileName = basename(file.path);

    var userToken = await UserService.getToken();

    TusClient fileUploadClient = TusClient(
      Uri.parse(API_BASE_URL + DATA_SPACE_ENDPOINT),
      file,
      store: TusMemoryStore(),
      headers: {'Authorization': 'Bearer $userToken'},
    );

    // ADD IMAGE LOCALLY
    MessageDto message = widget.messageSendingService.addPreparedImage(fileName, file.path, Uri.parse(API_BASE_URL + '/files/uploads/' + fileName).toString());
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
          widget.messageSendingService.sendImage(message);
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
      print('Error uploading image');
      print(exception); //TODO: Handling
    }
  }

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (context) {
        scaffold = Scaffold.of(context);
        return FloatingModal(
          child: Container(
            color: Colors.white,
            child: Column(children: [
              Container(
                  height: 60,
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: IconButton(
                        icon: Icon(Icons.close),
                        iconSize: 25,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                  ])
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 25),
                child: Row(children: [
                  buildShareItem(text: 'Send file', icon: Icons.photo_library, color: Colors.deepPurpleAccent, onTap: () {
                    openFilePicker();
                  }),
                ]),
              )
            ]),
          ),
        );
      }),
    );
  }

  void onUploadComplete(response) async {
  }

  void onUploadStart() async {
  }

  void onUploadError(error) {
    print(error);
  }
}

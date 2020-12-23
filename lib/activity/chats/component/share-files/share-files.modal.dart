import 'dart:convert';
import 'dart:io';

import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/messaging/message-sending.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/util/other/file-type-resolver.util.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:tus_client/tus_client.dart';

import '../../../../shared/modal/floating-modal.dart';

class ShareFilesModal extends StatefulWidget {
  final int userId;
  final int peerId;
  final int userSentNodeId;

  final String picturesPath;

  final Function(MessageDto, double) onProgress;

  final MessageSendingService messageSendingService;

  const ShareFilesModal({Key key, this.messageSendingService, this.onProgress, this.peerId, this.picturesPath, this.userId, this.userSentNodeId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShareFilesModalState();
}

class ShareFilesModalState extends BaseState<ShareFilesModal> {
  List<File> files;

  openFilePicker() async {
    Navigator.of(getScaffoldContext()).pop();

    files = await FilePicker.getMultiFile();

    files.forEach((file) {
      uploadAndSendFile(file);
    });
  }

  uploadAndSendFile(file) async {
    var fileName = basename(file.path);
    var fileType = FileTypeResolverUtil.resolve(extension(fileName));
    var fileSize = file.lengthSync();
    var fileUrl = Uri.parse(API_BASE_URL + '/files/uploads/' + fileName).toString();

    file = await file.copy(widget.picturesPath + '/' + fileName);

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
        fileUrl, fileSize, fileType);

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
}

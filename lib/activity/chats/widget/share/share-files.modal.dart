import 'dart:io';

import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/base/base.state.dart';

import '../../../../shared/modal/floating-modal.dart';

class ShareFilesModal extends StatefulWidget {
  final Function onSuccess;

  const ShareFilesModal({Key key, this.onSuccess}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShareFilesModalState();
}

class ShareFilesModalState extends BaseState<ShareFilesModal> {
  File file;

  openFilePicker() async {
    Navigator.of(getScaffoldContext()).pop();
    file = await FilePicker.getFile(onFileLoading: (status) {});

    var fileName = basename(file.path);
    widget.onSuccess(fileName, file.path, HttpClientService.getFileUlr(fileName));

    await HttpClientService.tusUpload(file,
        startF: onUploadStart,
        completeF: onUploadComplete,
        errF: onUploadError);
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

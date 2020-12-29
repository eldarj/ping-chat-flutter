

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:path/path.dart';
import 'package:flutterping/util/extension/duration.extension.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/main.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/shared/var/global.var.dart';

class DSDocument extends StatefulWidget {
  final DSNodeDto node;

  final String picturesPath;

  final int gridHorizontalSize;

  const DSDocument({Key key, this.node, this.picturesPath, this.gridHorizontalSize}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DSDocumentState();
}

class DSDocumentState extends BaseState<DSDocument> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (context) {
        scaffold = Scaffold.of(context);
        return buildMessageMedia();
      }),
    );
  }

  buildMessageMedia() {
    double iconContainerSize = widget.gridHorizontalSize == 4 ? 0 : 100 / widget.gridHorizontalSize;
    double nameContainerSize = DEVICE_MEDIA_SIZE.width / widget.gridHorizontalSize - iconContainerSize - 40;
    double iconSize = 40 / widget.gridHorizontalSize;

    String title = widget.node.nodeName;
    String filePath = widget.picturesPath + '/' + widget.node.nodeName;
    Widget iconWidget = Icon(Icons.insert_drive_file, color: Colors.grey.shade100, size: iconSize);

    return GestureDetector(
      onTap: () async {
        OpenFile.open(filePath);
      },
      onLongPressEnd: (details) {
        showMenu(
          context: scaffold.context,
          position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, 100000, 0),
          elevation: 8.0,
          items: [PopupMenuItem(value: 'DELETE', child: Text("Delete")),],
        ).then((value) {
          if (value == 'DELETE') {
            doDeleteMessage().then(onDeleteMessageSuccess, onError: onDeleteMessageError);
          }
        });
      },
      child: Container(
          color: Colors.grey.shade200,
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              widget.gridHorizontalSize == 4 ? Container() : Container(
                margin: EdgeInsets.only(right: 10),
                child: Container(
                    width: iconContainerSize, height: iconContainerSize,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: CompanyColor.blueDark
                    ),
                    child: iconWidget),
              ),
              Container(
                width: nameContainerSize,
                alignment: Alignment.centerLeft,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, overflow: TextOverflow.ellipsis, maxLines: 3),
                      Text(widget.node.fileSizeFormatted(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ]),
              )
            ],
          )),
    );
  }

  Future doDeleteMessage() async {
    try {
      var file = File(widget.picturesPath + '/' + widget.node.nodeName);
      file.delete();
    } catch(ignored) {}

    String url = '/api/data-space'
        '?nodeId=' + widget.node.id.toString() +
        '&fileName=' + basename(widget.node.nodeName);

    http.Response response = await HttpClientService.delete(url);

    if (response.statusCode != 200) {
      throw Exception();
    }

    return true;
  }

  onDeleteMessageSuccess(_) async {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('Izbrisali ste datoteku.'));
    await Future.delayed(Duration(seconds: 2));
    dataSpaceDeletePublisher.subject.add(widget.node.id);
  }

  onDeleteMessageError(error) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }
}

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';

class DSDocument extends StatefulWidget {
  final DSNodeDto node;

  final String picturesPath;

  final int gridHorizontalSize;

  final Function(DSNodeDto) onNodeSelected;

  final bool multiSelectEnabled;

  const DSDocument({Key key, this.node, this.picturesPath, this.gridHorizontalSize, this.onNodeSelected,
    this.multiSelectEnabled = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DSDocumentState();
}

class DSDocumentState extends BaseState<DSDocument> {
  String filePath;

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
    filePath = widget.picturesPath + '/' + widget.node.nodeName;

    return Material(
      color: Colors.grey.shade200,
      child: InkWell(
        onTap: widget.multiSelectEnabled ? () {
          widget.onNodeSelected.call(widget.node);
        } : () async {
          OpenFile.open(filePath);
        },
        onLongPress: widget.multiSelectEnabled ? () {
          widget.onNodeSelected.call(widget.node);
        } : null,
        child: Container(
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    children: [
                      widget.gridHorizontalSize == 4 ? Container() : Container(
                        margin: EdgeInsets.only(right: 5),
                        child: Container(
                            width: iconContainerSize, height: iconContainerSize,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: CompanyColor.blueDark
                            ),
                            child: Icon(Icons.insert_drive_file, color: Colors.grey.shade100, size: iconSize)),
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
                  ),
                ),
                buildMoreButton(),
              ],
            )),
      ),
    );
  }

  GestureDetector buildMoreButton() {
    return GestureDetector(
      onTapDown: (details) async {
        widget.multiSelectEnabled ? () {} : showDSMenu(details);
      },
      child: Container(
        alignment: Alignment.topRight,
        padding: EdgeInsets.only(top: 7.5, right: 2.5),
        constraints: BoxConstraints(
            maxWidth: 50, maxHeight: 50
        ),
        child: Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
      )
    );
  }

  void showDSMenu(details) {
    showMenu(
      context: scaffold.context,
      position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, 100000, 0),
      elevation: 8.0,
      items: [
        PopupMenuItem(value: 'DELETE', child: Text("Delete")),
        PopupMenuItem(value: 'OPEN', child: Text("Open")),
      ],
    ).then((value) {
      if (value == 'DELETE') {
        doDeleteMessage().then(onDeleteMessageSuccess, onError: onDeleteMessageError);
      } else if (value == 'OPEN') {
        OpenFile.open(filePath);
      }
    });
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
    scaffold.showSnackBar(SnackBarsComponent.info('Deleted'));
    await Future.delayed(Duration(seconds: 2));
    dataSpaceDeletePublisher.subject.add(widget.node.id);
  }

  onDeleteMessageError(error) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }
}

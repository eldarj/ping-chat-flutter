import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/contacts/search-contacts.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/modal/floating-modal.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';

class DSDocument extends StatefulWidget {
  final DSNodeDto node;

  final String picturesPath;

  final int gridHorizontalSize;

  final Function(DSNodeDto) onNodeSelected;

  final bool multiSelectEnabled;

  final bool displayShare;

  final File file;

  const DSDocument({Key key, this.node, this.picturesPath, this.gridHorizontalSize, this.onNodeSelected,
    this.multiSelectEnabled = false,
    this.displayShare = false, this.file}) : super(key: key);

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

  buildMoreButton() {
    return Material(
      color: Colors.grey.shade200,
      child: InkWell(
          onTap: () async {
            widget.multiSelectEnabled ? () {} : showDSMenu();
          },
          child: Container(
            height: 35, width: 25,
            alignment: Alignment.topRight,
            padding: EdgeInsets.only(top: 7.5, right: 2.5),
            child: Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
          )
      ),
    );
  }

  showDSMenu() {
    List<Widget> items = [];
    items.add(ListTile(leading: Icon(Icons.radio_button_checked_rounded),
        title: Text('Open'),
        onTap: () {
          Navigator.of(scaffold.context).pop();
          OpenFile.open(filePath);
        }));

    if (widget.displayShare) {
      items.add(ListTile(leading: Icon(Icons.send),
          title: Text('Send'),
          onTap: () {
            NavigatorUtil.replace(scaffold.context, SearchContactsActivity(
                sharedNode: widget.node,
                sharedFile: widget.file,
                picturesPath: widget.picturesPath,
                type: SearchContactsType.SHARE
            ));
          }));
    }

    items.add(ListTile(
        leading: Icon(Icons.delete_outline),
        title: Text('Delete'),
        onTap: () {
          Navigator.of(scaffold.context).pop();
          doDeleteMessage().then(onDeleteMessageSuccess, onError: onDeleteMessageError);
        }));

    showCustomModalBottomSheet(context: scaffold.context,
        expand: false,
        containerWidget: (_, animation, child) => FloatingModal(child: child),
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [Shadows.bottomShadow()]
                ),
                padding: EdgeInsets.only(left: 20, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 15, bottom: 15),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DOCUMENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                            Container(
                              width: DEVICE_MEDIA_SIZE.width - 80,
                              child: Text(widget.node.nodeName,
                                  overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]
                      ),
                    ),
                    Container(
                      child: IconButton(
                        icon: Icon(Icons.close),
                        iconSize: 25,
                        onPressed: () {
                          Navigator.of(scaffold.context).pop();
                        },
                      ),
                    )
                  ],
                ),
              ),
              Wrap(children: items),
            ],
          );
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

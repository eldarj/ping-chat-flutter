import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/reply-dto.model.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/messaging/message-deleted.publisher.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/component/loading-button.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/dialog/generic-alert.dialog.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path/path.dart' show basename;
import 'package:photo_view/photo_view.dart';
import 'package:share/share.dart';

class ImageViewerActivity extends StatefulWidget {
  final int messageId;

  final int nodeId;

  final MessageDto message;

  final File file;

  final String contactName;

  final String sender;

  final int timestamp;

  final ReplyDto reply;

  const ImageViewerActivity({Key key,
    this.message,
    this.messageId, this.nodeId,
    this.file, this.sender, this.timestamp, this.contactName,
    this.reply
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => ImageViewerActivityState();
}

class ImageViewerActivityState extends BaseState<ImageViewerActivity> {
  int userId;

  initialize() async {
    userId = await UserService.getUserId();
  }

  @override
  initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return Container(
            child: Stack(
              alignment: Alignment.topLeft,
              children: [
                Container(
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: <Widget>[
                      PhotoView(
                        imageProvider: FileImage(widget.file),
                      ),
                      Container(
                          color: Colors.black87,
                          height: 160,
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.all(20),
                          child: buildDescriptionSection())
                    ],
                  ),
                ),
                Container(
                  height: 85, color: Colors.black87,
                  padding: EdgeInsets.only(top: 30, left: 5, right: 10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    IconButton(onPressed: () {
                      Navigator.pop(context);
                    }, icon: Icon(Icons.close), color: Colors.white),
                    Container(child: Row(
                      children: <Widget>[
                        IconButton(onPressed: () {
                          Share.shareFiles([widget.file.path]);
                        }, icon: Icon(Icons.share), color: Colors.white),
                        LoadingButton(color: Colors.transparent, child: Icon(Icons.delete, color: Colors.white),
                            displayLoader: displayLoader, onPressed: () {
                              var dialog = GenericAlertDialog(
                                  title: "Delete",
                                  message: "Both the message and image will be deleted from the device as well",
                                  onPostivePressed: () {
                                    doDeleteMessage().then(onDeleteMessageSuccess, onError: onDeleteMessageError);
                                  },
                                  positiveBtnText: 'Delete',
                                  negativeBtnText: 'Cancel');
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) => dialog);
                            }),
                      ],
                    )),
                  ]),
                ),
              ],
            ),
          );
        })
    );
  }

  Widget buildDescriptionSection() {
    Widget w = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          displayMapLocation() ? Container(
            margin: EdgeInsets.only(bottom: 5),
            child: Text(widget.reply != null ? widget.reply.text : widget.message.text, style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400
            ))
          ) : Container(),
          widget.sender != null ? Text(widget.sender, style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold
          )) : Container(),
          Text(DateTimeUtil.convertTimestampToTimeAgo(widget.timestamp), style: TextStyle(
              color: Colors.white,
              fontSize: 12
          )),
    ]);

    return w;
  }

  bool displayMapLocation() {
    bool isMapLocation = false;

    if (widget.reply != null) {
      isMapLocation = widget.reply.messageType == 'MAP_LOCATION';
    } else if (widget.message != null) {
      isMapLocation =  widget.message.messageType == 'MAP_LOCATION';
    }

    return isMapLocation;
  }

  Future doDeleteMessage() async {
    setState(() {
      displayLoader = true;
    });

    String url;
    if (widget.messageId != null) {
      url = '/api/messages/${widget.messageId}?userId=$userId';
    } else {
      url = '/api/data-space'
          '?nodeId=' + widget.nodeId.toString() +
          '&fileName=' + basename(widget.file.path); // TODO: Handle this

      try {
        widget.file.delete();
      } catch(ignored) {}
    }

    http.Response response = await HttpClientService.delete(url);

    await Future.delayed(Duration(seconds: 1));

    if (response.statusCode != 200) {
      throw Exception();
    }

    return true;
  }

  onDeleteMessageSuccess(_) async {
    if (widget.messageId != null) {
      messageDeletedPublisher.emitMessageDeleted(widget.message);
    } else {
      dataSpaceDeletePublisher.subject.add(widget.nodeId);
    }

    Navigator.pop(scaffold.context, {'deleted': true});
  }

  onDeleteMessageError(error) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }
}

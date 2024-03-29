import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/data-space/component/ds-document.component.dart';
import 'package:flutterping/activity/data-space/component/ds-media.component.dart';
import 'package:flutterping/activity/data-space/component/ds-recording.component.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/loading-button.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/dialog/generic-alert.dialog.dart';
import 'package:flutterping/shared/info/info.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;

class ContactSharedActivity extends StatefulWidget {
  final ClientDto peer;

  final String peerContactName;

  final int contactBindingId;

  final String picturesPath;


  const ContactSharedActivity({Key key, this.peer, this.peerContactName, this.contactBindingId, this.picturesPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ContactSharedActivityState();
}

class ContactSharedActivityState extends BaseState<ContactSharedActivity> {
  static const String STREAMS_LISTENER_ID = "ContactSharedStreamsListener";

  int userId;

  bool displayLoader = true;

  List<DSNodeDto> nodes = new List();

  int gridHorizontalSize = 2;

  ScrollController gridScrollController = new ScrollController();

  double contentOpacity = 1;

  bool gotoTopButtonVisible = false;

  bool displayDeleteLoader = false;

  onInit() async {
    userId = await UserService.getUserId();
    doGetSharedData().then(onGetSharedDataSuccess, onError: onGetSharedDataError);

    dataSpaceDeletePublisher.addListener(STREAMS_LISTENER_ID, (int nodeId) {
      setState(() {
        nodes.removeWhere((element) => element.id == nodeId);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    onInit();
  }

  @override
  void dispose() {
    super.dispose();
    if (dataSpaceDeletePublisher != null) {
      dataSpaceDeletePublisher.removeListener(STREAMS_LISTENER_ID);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar.getBackAppBar(getScaffoldContext, titleWidget: Container(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Shared media', style: TextStyle(fontWeight: FontWeight.normal)),
          Text(widget.peerContactName, style: TextStyle(fontSize: 16, color: Colors.grey))
        ]),
      )),
      body: Builder(builder: (context) {
        scaffold = Scaffold.of(context);
        return AnimatedOpacity(
          opacity: contentOpacity,
          duration: Duration(milliseconds: 250),
          child: buildContent(),
        );
      }),
      floatingActionButton: AnimatedOpacity(
        duration: Duration(milliseconds: 500),
        opacity: gotoTopButtonVisible ? 1 : 0,
        child: FloatingActionButton(
          mini: true,
          backgroundColor: Colors.white,
          elevation: 1,
          child: Icon(Icons.arrow_upward, color: CompanyColor.blueDark),
          onPressed: () {
            gridScrollController.animateTo(0.0,
                curve: Curves.easeOut,
                duration: const Duration(seconds: 1));
          },
        ),
      ),
    );
  }

  buildContent() {
    Widget w = ActivityLoader.build();

    if (!displayLoader) {
      if (!isError) {
        if (nodes != null && nodes.length > 0) {
          w = GestureDetector(
            onHorizontalDragEnd: (DragEndDetails details) async {
              if (details.primaryVelocity > 0) {
                if (gridHorizontalSize < 4) {
                  setState(() {
                    gridHorizontalSize++;
                    contentOpacity = 0.5;
                  });
                  await Future.delayed(Duration(milliseconds: 500));
                  setState(() {
                    contentOpacity = 1;
                  });
                }
              } else if (details.primaryVelocity < 0) {
                if (gridHorizontalSize > 1) {
                  setState(() {
                    gridHorizontalSize--;
                    contentOpacity = 0.5;
                  });
                  await Future.delayed(Duration(milliseconds: 500));
                  setState(() {
                    contentOpacity = 1;
                  });
                }
              }
            },
            child: NotificationListener(
              onNotification: (notification) {
                bool newVisibility;
                if (gridScrollController.position.pixels > 350) {
                  newVisibility = true;
                } else {
                  newVisibility = false;
                }

                if (gotoTopButtonVisible != newVisibility) {
                  setState(() {
                    gotoTopButtonVisible = newVisibility;
                  });
                }

                return true;
              },
              child: GridView.builder(
                  controller: gridScrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: 5, mainAxisSpacing: 5, crossAxisCount: gridHorizontalSize),
                  itemCount: nodes.length, itemBuilder: (context, index) {
                var node = nodes[index];
                return buildSingleNode(node);
              }),
            ),
          );
        } else {
          w = Center(
            child: Container(
              margin: EdgeInsets.all(25),
              child: Text("You don't have any shared media", style: TextStyle(color: Colors.grey)),
            ),
          );
        }
      } else {
        w = InfoComponent.errorPanda(onButtonPressed: () async {
          setState(() {
            displayLoader = true;
            isError = false;
          });

          doGetSharedData().then(onGetSharedDataSuccess, onError: onGetSharedDataError);
        });
      }
    }

    return w;
  }

  // Get shared data
  Future doGetSharedData() async {
    String url = '/api/data-space/shared'
        '?userId=' + userId.toString() +
        '&contactId=' + widget.peer.id.toString();

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return List<DSNodeDto>.from(response.decode().map((e) => DSNodeDto.fromJson(e))).toList();
  }

  void onGetSharedDataSuccess(nodes) async {
    this.nodes = nodes;

    setState(() {
      displayLoader = false;
      isError = false;
    });
  }

  void onGetSharedDataError(Object error) {
    print(error);
    setState(() {
      isError = true;
      displayLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () async {
      setState(() {
        displayLoader = true;
        isError = false;
      });

      doGetSharedData().then(onGetSharedDataSuccess, onError: onGetSharedDataError);
    }));
  }

  buildSingleNode(DSNodeDto node) {
    String filePath = widget.picturesPath + '/' + node.nodeName;

    File file = File(filePath);
    bool isFileValid = file.existsSync() && file.lengthSync() > 0;

    Widget _w;

    if (!isFileValid) {
      _w = Icon(Icons.broken_image_outlined, color: Colors.grey.shade400);
    } else if (node.nodeType == 'IMAGE' || node.nodeType == 'MAP_LOCATION') {
      _w = GestureDetector(
        onTap: () async {
          NavigatorUtil.push(context,
              ImageViewerActivity(
                  nodeId: node.id,
                  sender: widget.peerContactName,
                  timestamp: node.createdTimestamp,
                  file: File(filePath))
          );
        },
        child: Image.file(File(filePath), fit: BoxFit.cover, cacheWidth: 200),
      );
    } else if (node.nodeType == 'RECORDING') {
      _w = DSRecording(node: node, gridHorizontalSize: gridHorizontalSize, picturesPath: widget.picturesPath);
    } else if (node.nodeType == 'MEDIA') {
      _w = DSMedia(node: node, gridHorizontalSize: gridHorizontalSize, picturesPath: widget.picturesPath);
    } else if (node.nodeType == 'FILE') {
      _w = DSDocument(node: node, gridHorizontalSize: gridHorizontalSize, picturesPath: widget.picturesPath);
    } else {
      _w = Container(
          color: Colors.grey.shade100,
          child: Center(child: Text('Unrecognized media', style: TextStyle(color: Colors.grey))));
    }

    return _w;
  }
}

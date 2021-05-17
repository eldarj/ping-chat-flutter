import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/data-space/component/ds-media.component.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/info/error.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
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
    dataSpaceDeletePublisher.removeListener(STREAMS_LISTENER_ID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar.getBackAppBar(getScaffoldContext, titleWidget:           Container(
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
        w = ErrorComponent.build(actionOnPressed: () async {
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
    bool fileExists;
    String filePath;
    filePath = widget.picturesPath + '/' + node.nodeName;

    fileExists = File(filePath).existsSync();

    Widget _w;

    if (node.nodeType == 'IMAGE') {
      _w = GestureDetector(
        onTap: () async {
          var result = await NavigatorUtil.push(context,
              ImageViewerActivity(
                  nodeId: node.id,
                  sender: widget.peerContactName,
                  timestamp: node.createdTimestamp,
                  file: File(filePath)));

          if (result != null && result['deleted'] == true) {
            setState(() {
              nodes.removeWhere((element) => element.id == node.id);
            });
          }
        },
        child: fileExists ? Image.file(File(filePath), fit: BoxFit.cover)
            : Text('TODO: fixme'),
      );
    } else if (node.nodeType == 'RECORDING' || node.nodeType == 'MEDIA' || node.nodeType == 'FILE') {
      _w = DSMedia(node: node, gridHorizontalSize: gridHorizontalSize, picturesPath: widget.picturesPath);
    } else {
      _w = Center(child: Text('Unrecognized media.'));
    }

    return Container(
        child: fileExists ? _w
            : Text('TODO: fixme'));
  }
}

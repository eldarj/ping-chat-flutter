import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/util/widget/base.state.dart';

class SharedSpaceActivity extends StatefulWidget {
  final ClientDto peer;

  final String peerContactName;

  final int contactBindingId;

  final String picturesPath;


  const SharedSpaceActivity({Key key, this.peer, this.peerContactName, this.contactBindingId, this.picturesPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SharedSpaceActivityState();
}

class SharedSpaceActivityState extends BaseState<SharedSpaceActivity> {
  int userId;

  bool displayLoader = true;

  List<DSNodeDto> nodes = new List();

  int gridHorizontalSize = 2;

  onInit() async {
    userId = await UserService.getUserId();
    doGetSharedData().then(onGetSharedDataSuccess, onError: onGetSharedDataError);
  }

  @override
  void initState() {
    super.initState();
    onInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar.getBackAppBar(getScaffoldContext, titleWidget:           Container(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dijeljeno', style: TextStyle(fontWeight: FontWeight.normal)),
          Text(widget.peerContactName, style: TextStyle(fontSize: 16, color: Colors.grey))
        ]),
      )),
      body: Builder(builder: (context) {
        scaffold = Scaffold.of(context);
        return Container(
          child: buildContent(),
        );
      }),
    );
  }

  buildContent() {
    Widget w = Center(child: Spinner());

    if (!displayLoader) {
      if (!isError) {

        w = GestureDetector(
          onHorizontalDragEnd: (DragEndDetails details) {
            if (details.primaryVelocity > 0) {
              setState(() {
                if (gridHorizontalSize < 4) {
                  gridHorizontalSize++;
                }
              });
            } else if (details.primaryVelocity < 0) {
              setState(() {
                if (gridHorizontalSize > 1) {
                  gridHorizontalSize--;
                }
              });
            }
          },
          child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: 10, mainAxisSpacing: 10, crossAxisCount: gridHorizontalSize),
              itemCount: nodes.length, itemBuilder: (context, index) {
            var node = nodes[index];
            return buildSingleNode(node);
          }),
        );
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
    String url = '/api/data-space'
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
    if (node.ownerId == userId) {
      filePath = node.pathOnSourceDevice;
    } else {
      filePath = widget.picturesPath + '/' + node.nodeName;
    }

    fileExists = File(filePath).existsSync();

    return Container(
        constraints: BoxConstraints(
            maxWidth: 100, maxHeight: 100, minHeight: 100, minWidth: 100
        ),
        child: fileExists ? Image.file(File(filePath), fit: BoxFit.cover)
            : Text('TODO: fixme'));
  }
}

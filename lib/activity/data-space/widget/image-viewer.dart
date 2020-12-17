import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' show basename;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/component/loading-button.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share/share.dart';

// TODO: Change to stateless
class ImageViewerActivity extends StatefulWidget {
  final File file;

  final String contactName;

  final String sender;

  final int timestamp;

  const ImageViewerActivity({Key key, this.file, this.sender, this.timestamp, this.contactName}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ImageViewerActivityState();
}

class ImageViewerActivityState extends BaseState<ImageViewerActivity> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return Container(
            color: Colors.purple,
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
                          height: 100,
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.all(20),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(widget.sender, style: TextStyle(color: Colors.white,
                                fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(DateTimeUtil.convertTimestampToTimeAgo(widget.timestamp),
                                style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                          )
                      )
                    ],
                  ),
                ),
                Container(
                  height: 85, color: Colors.black87,
                  padding: EdgeInsets.only(top: 30, left: 10, right: 10),
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
                              setState(() {
                                displayLoader = true;
                              });
                              doDelete().then(onDeleteSuccess, onError: onDeleteError);
                            }),
                      ],
                    ))
                  ]),
                ),
              ],
            ),
          );
        })
    );
  }

  Future doDelete() async {
    String url = '/api/data-space/upload/ph?fileName=' + basename(widget.file.path);

    http.Response response = await HttpClientService.delete(url);

    if (response.statusCode != 204) {
      throw Exception();
    }

    return true;
  }

  onDeleteSuccess(result) async {
    setState(() {
      displayLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('Izbrisali ste datoteku.'));

    await Future.delayed(Duration(seconds: 2));

    Navigator.pop(context, {'deleted': true});
  }

  onDeleteError(error) {
    setState(() {
      displayLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }
}

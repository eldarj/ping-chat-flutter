import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutterping/activity/data-space/image/delete.dialog.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/dropdown-banner/dropdown-banner.component.dart';
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
import 'package:flutterping/util/widget/base.state.dart';
import 'package:flutterping/util/other/date-time.util.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share/share.dart';

// TODO: Change to stateless
class ImageViewerActivity extends StatefulWidget {
  final MessageDto message;

  final File file;

  final String contactName;

  final String sender;

  final int timestamp;

  const ImageViewerActivity({Key key, this.message, this.file, this.sender, this.timestamp, this.contactName}) : super(key: key);

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
                              var dialog = DeleteImageAlertDialog(
                                  title: "Izbriši sliku",
                                  message: "Ukoliko je kontakt aktivirao direktno spremanje na uređaj,"
                                      " datoteku neće biti moguće izbrisati sa istog.",
                                  onPostivePressed: () {
                                    doDeleteMessage().then(onDeleteMessageSuccess, onError: onDeleteMessageError);
                                  },
                                  positiveBtnText: 'Izbriši',
                                  negativeBtnText: 'Odustani');
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) => dialog);

                              // DropdownBanner.showBanner(
                              //   icon: Icon(Icons.close),
                              //   text: 'Ukoliko je kontakt aktivirao direktno '
                              //       'spremanje na uređaj, datoteku neće biti moguće izbrisati sa istog.',
                              //   actions: [
                              //     FlatButton(onPressed: () {
                              //       doDeleteMessage().then(onDeleteMessageSuccess, onError: onDeleteMessageError);
                              //     }, child: Text('Izbriši'), color: Colors.grey.shade200,)
                              //   ],
                              // );
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

  Future doDeleteMessage() async {
    String url = '/api/data-space/upload/ph'
        '?fileName=' + basename(widget.file.path);

    http.Response response = await HttpClientService.delete(url);

    if (response.statusCode != 204) {
      throw Exception();
    }

    return true;
  }

  onDeleteMessageSuccess(result) async {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('Izbrisali ste datoteku.'));

    await Future.delayed(Duration(seconds: 2));

    widget.message.deleted = true;
    wsClientService.messageDeletedPub.sendEvent(widget.message, '/messages/deleted');

    Navigator.pop(context, {'deleted': false});
    // await widget.file.delete(); // TODO: Delete original source file (or createa a 'sent' copy and delete that?)
  }

  onDeleteMessageError(error) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }
}

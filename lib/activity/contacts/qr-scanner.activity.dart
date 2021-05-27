

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/activity/contacts/single/single-contact.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/service/http/http-client.service.dart';


class QrScannerActivity extends StatefulWidget {
  final ClientDto user;

  const QrScannerActivity({Key key, this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() => QrScannerActivityState();
}

class QrScannerActivityState extends BaseState<QrScannerActivity> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  Barcode result;

  QRViewController qrViewController;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget render() {
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
                    QRView(
                      key: qrKey,
                      overlay: QrScannerOverlayShape(
                          borderColor: Colors.white,
                          borderRadius: 2,
                          borderWidth: 5.0
                      ),
                      onQRViewCreated: onInit,
                    ),
                    Container(
                        color: Colors.black54,
                        child: buildDetailsSection())
                  ],
                ),
              ),
              Container(
                height: 85, color: Colors.black54,
                padding: EdgeInsets.only(top: 30, left: 5, right: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  IconButton(onPressed: () {
                    Navigator.pop(context);
                  }, icon: Icon(Icons.close), color: Colors.white),
                ]),
              )
            ],
          ),
        );
      })
    );
  }

  Widget buildDetailsSection() {
    Widget w;

    if (displayLoader) {
      w = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Adding ${result.code}', style: TextStyle(
            color: Colors.grey.shade400
        )),
        Spinner(size: 20),
      ]);
    } else {
      w = Row(children: [
        Text('Add contact by scanning a Ping profile QR Code', style: TextStyle(
          color: Colors.grey.shade400
        ))
      ]);
    }

    return Container(
        height: 45,
        padding: EdgeInsets.only(left: 10, right: 10),
        child: w
    );
  }

  void onInit(QRViewController qrViewController) {
    this.qrViewController = qrViewController;
    qrViewController.scannedDataStream.listen((scanData) async {
      if (!displayLoader) {
        await qrViewController.pauseCamera();
        result = scanData;

        if (result.code.startsWith('+')) {
            doAddContact(result.code).then(onAddContactSuccess, onError: onAddContactError);

        } else {
          scaffold.removeCurrentSnackBar();
          scaffold.showSnackBar(SnackBarsComponent.error(
              content: 'Unrecognized QR Code, please try again',
              actionOnPressed: () async {
                await qrViewController.resumeCamera();
              }));
        }
      }
    });
  }

  Future<ContactDto> doAddContact(String contactPhoneNumber) async {
    setState(() {
      displayLoader = true;
    });

    http.Response response = await HttpClientService.post('/api/contacts/qr', body: contactPhoneNumber);

    await Future.delayed(Duration(seconds: 2));

    if (response.statusCode != 200) {
      throw new Exception();
    }

    return ContactDto.fromJson(json.decode(response.body));
  }

  void onAddContactSuccess(ContactDto contactDto) async {
    scaffold.showSnackBar(SnackBarsComponent.success('You successfully added ${contactDto.contactName}'
        ' to your contacts',
        duration: Duration(seconds: 4)
    ));

    await Future.delayed(Duration(seconds: 2));

    NavigatorUtil.replace(context, SingleContactActivity(
      peer: contactDto.contactUser,
      userId: widget.user.id,
      contactName: contactDto.contactName,
      contactPhoneNumber: contactDto.contactPhoneNumber,
      contactBindingId: contactDto.contactBindingId,
      favorite: false,
    ));
  }

  void onAddContactError(error) async {
    print(error);

    setState(() { displayLoader = false; });

    scaffold.showSnackBar(SnackBarsComponent.error(
        content: 'Couldn\'t add contact, please try again',
        actionOnPressed: () async {
          await qrViewController.resumeCamera();
        }));
  }

  @override
  void dispose() {
    qrViewController?.dispose();
    super.dispose();
  }
}

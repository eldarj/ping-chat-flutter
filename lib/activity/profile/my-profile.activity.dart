import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/profile/profile-image-upload/profile-image-upload.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/country-icon.component.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MyProfileActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new MyProfileActivityState();
}

class MyProfileActivityState extends BaseState<MyProfileActivity> {
  var displayLoader = true;

  DateFormat dateFormat = DateFormat("dd.MM.yy");
  ClientDto clientDto;
  String createdAtFormatted;

  getFormattedDate(timestamp) {
    if (timestamp is int) {
      return dateFormat.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
    }
    return dateFormat.format(DateTime.parse(timestamp));
  }

  pushProfileImageUploadActivity() async {
    var savedProfileImagePath = await NavigatorUtil.push(context, ProfileImageUploadActivity());
    if (savedProfileImagePath != null) {
      setState(() {
        clientDto.profileImagePath = savedProfileImagePath;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    doGetProfileData().then(onGetProfileDataSuccess, onError: onGetProfileDataError);
  }

  @override
  preRender() {
    appBar = BaseAppBar.getBackAppBar(getScaffoldContext, titleText: 'My Profile');
    drawer = new NavigationDrawerComponent();
  }

  @override
  Widget render() {
    return buildActivityContent();
  }

  Widget buildActivityContent() {
    Widget widget = Center(child: Spinner());
    if (!displayLoader) {
      if (!isError) {
        widget = Container(
            child: ListView(children: [
              Container(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  decoration: BoxDecoration(
                      color: Colors.white
                  ),
                  child: Column(children: [
                    GestureDetector(
                      onTap: pushProfileImageUploadActivity,
                      child: Container(
                          margin: EdgeInsets.only(left: 5, right: 10),
                          child: Stack(
                            alignment: AlignmentDirectional.bottomEnd,
                            children: [
                              new RoundProfileImageComponent(url: clientDto.profileImagePath,
                                  border: Border.all(color: Colors.grey.shade200, width: 1),
                                  height: 150, width: 150, borderRadius: 20),
                              Container(
                                  margin: EdgeInsets.all(5),
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: Theme.of(context).accentColor,
                                      boxShadow: [BoxShadow(color: Colors.grey.shade300, offset: Offset.fromDirection(1))]
                                  ),
                                  child: Icon(Icons.edit, color: Colors.white, size: 15))
                            ],
                          )
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              "Hello there,",
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 24),
                            ),
                            Text(clientDto.firstName + ' ' + clientDto.lastName,
                                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 27)),
                          ]),
                        ),
                      ],
                    ),
                  ])
              ),
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).backgroundColor,
                    boxShadow: [Shadows.topShadow()]
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                          margin: EdgeInsets.only(left: 10, top: 10),
                          child: buildTwoColumns([
                            buildSection('Broj telefona', text: clientDto.countryCode.dialCode + " " + clientDto.phoneNumber),
                          ], [
                            buildSection('Račun kreiran', text: createdAtFormatted),
                          ])
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 20, bottom: 10),
                        child: Row(
                          children: [
                            Container(
                                margin: EdgeInsets.only(right: 10, left: 1),
                                child: CountryIconComponent
                                    .buildCountryIcon(clientDto.countryCode.countryName, height: 15, width: 15)
                            ),
                            Container(
                                child: Text(clientDto.countryCode.countryName)
                            )
                          ],
                        ),
                      ),
                    ]
                ),
              )
            ])
        );
      } else {
        widget = ErrorComponent.build(actionOnPressed: () async {
          scaffold.removeCurrentSnackBar();
          setState(() {
            displayLoader = true;
            isError = false;
          });

          doGetProfileData().then(onGetProfileDataSuccess, onError: onGetProfileDataError);
        });
      }
    }

    return widget;
  }


  Widget buildSection(title, {text, child, titleLeftMargin: 0.0}) {
    if (child == null && text is int) {
      text = text.toString();
    }
    return Container(
      margin: EdgeInsets.only(left: 12.5, bottom: 15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            margin: EdgeInsets.only(left: titleLeftMargin, bottom: 5),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold))
        ),
        child != null ? child : Text(text != null ? text : "")
      ]),
    );
  }

  Widget buildTwoColumns(leftChildren, rightChildren) {
    return Wrap(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: leftChildren)
            ),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rightChildren
                )
            )
          ]
      )
    ]);
  }

  Future<void> doGetProfileData() async {
    var user = await UserService.getUser();
    http.Response response = await HttpClientService.get('/api/users/${user.id}');

    if (response.statusCode != 200) {
      throw new Exception();
    }

    dynamic jsonDecoded = response.decode();
    return ClientDto.fromJson(jsonDecoded);
  }

  void onGetProfileDataSuccess(clientDto) async {
    this.clientDto = clientDto;
    await UserService.setUser(clientDto);
    createdAtFormatted = getFormattedDate(clientDto.joinedTimestamp);

    setState(() {
      displayLoader = false;
      isError = false;
    });
  }

  void onGetProfileDataError(Object error) {
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

      doGetProfileData().then(onGetProfileDataSuccess, onError: onGetProfileDataError);
    }));
  }
}

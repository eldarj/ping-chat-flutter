import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/profile/profile-image-upload/profile-image-upload.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/user-settings.dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/profile/profile.publisher.dart';
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
import 'package:qr_flutter/qr_flutter.dart';

class MyProfileActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new MyProfileActivityState();
}

class MyProfileActivityState extends BaseState<MyProfileActivity> {
  var displayLoader = true;

  DateFormat dateFormat = DateFormat("dd.MM.yy");
  ClientDto clientDto;
  String createdAtFormatted;

  bool displaySettingsLoader = false;

  getFormattedDate(timestamp) {
    if (timestamp is int) {
      return dateFormat.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
    }
    return dateFormat.format(DateTime.parse(timestamp));
  }

  pushProfileImageUploadActivity() async {
    var savedProfileImagePath = await NavigatorUtil.push(context, ProfileImageUploadActivity());

    if (savedProfileImagePath != null) {
      profilePublisher.emitProfileImageUpdate(savedProfileImagePath);
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
              buildHeader(),
              buildQRCode(),
              buildSettings(),
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
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800))
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

  Widget buildHeader() {
    return Container(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [Shadows.bottomShadow()]
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GestureDetector(
            onTap: pushProfileImageUploadActivity,
            child: Container(
                margin: EdgeInsets.only(left: 5, right: 10),
                child: Center(
                  child: Stack(
                    alignment: AlignmentDirectional.bottomEnd,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 15, spreadRadius: 1)],
                            borderRadius: BorderRadius.all(Radius.circular(20))
                        ),
                        child: new RoundProfileImageComponent(url: clientDto.profileImagePath,
                            border: Border.all(color: Colors.grey.shade200, width: 1),
                            height: 200, width: 200, borderRadius: 20),
                      ),
                      Container(
                          margin: EdgeInsets.all(5),
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: CompanyColor.accentGreenDark,
                              boxShadow: [BoxShadow(color: Colors.grey.shade300, offset: Offset.fromDirection(1))]
                          ),
                          child: Icon(Icons.edit, color: Colors.white, size: 15))
                    ],
                  ),
                )
            ),
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    "Hello there,",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 26),
                  ),
                  Text(clientDto.firstName + ' ' + clientDto.lastName,
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 29)),
                ]),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: buildTwoColumns([
              buildSection('Phone number', text: clientDto.countryCode.dialCode + " " + clientDto.phoneNumber),
            ], [
              buildSection('Joined', text: createdAtFormatted),
            ]),
          ),
          Container(
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: Row(
              children: [
                Container(
                    margin: EdgeInsets.only(right: 10, left: 12.5),
                    child: CountryIconComponent
                        .buildCountryIcon(clientDto.countryCode.countryName, height: 15, width: 15)
                ),
                Container(
                    child: Text(clientDto.countryCode.countryName)
                )
              ],
            ),
          ),
        ])
    );
  }

  Widget buildSettings() {
    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          boxShadow: [Shadows.bottomShadow()]
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 20,
                    margin: EdgeInsets.only(left: 10, right: 10),
                    child: Text("Preferences", style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey.shade800
                    )),
                  ),
                  Spinner(size: 20, visible: displaySettingsLoader)
                ],
              ),
            ),
            IgnorePointer(
              ignoring: displaySettingsLoader,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: displaySettingsLoader ? 0.5 : 1,
                child: Column(children: [
                  buildPreferencesButton(
                      Icons.vibration,
                      'Vibrate',
                      'Vibrate on new messages',
                      clientDto.userSettings.vibrate,
                      (value) {
                        clientDto.userSettings.vibrate = value;
                        doUpdateUserSettings().then(onSettingsSuccess, onError: onSettingsError);
                      }),
                  buildPreferencesButton(
                      Icons.notifications_none,
                      'Notifications',
                      'Receive incoming notifications',
                      clientDto.userSettings.receiveNotifications,
                          (value) {
                        clientDto.userSettings.receiveNotifications = value;
                        doUpdateUserSettings().then(onSettingsSuccess, onError: onSettingsError);
                      }),
                  buildPreferencesButton(
                      Icons.amp_stories,
                      'Dark mode',
                      'Turn dark mode ' + (clientDto.userSettings.darkMode ? 'off' : 'on'),
                      clientDto.userSettings.darkMode,
                          (value) {
                        clientDto.userSettings.darkMode = value;
                        doUpdateUserSettings().then(onSettingsSuccess, onError: onSettingsError);
                      }),
                ])
              ),
            ),
          ]
      ),
    );
  }

  buildPreferencesButton(icon, text, description, value, onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onChanged.call(!value);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    child: Icon(icon, color: Colors.grey.shade700),
                    margin: EdgeInsets.only(left: 7.5, right: 20),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade50,
                    ),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text,
                          style: TextStyle(color: Colors.grey.shade800)),
                      Text(description,
                          style: TextStyle(color: Colors.grey.shade400))
                    ],
                  ),
                ]),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: CompanyColor.accentGreenDark,
                ),
              ]
          ),
        ),
      ),
    );
  }

  Widget buildQRCode() {
    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          boxShadow: [Shadows.bottomShadow()]
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("QR Code", style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey.shade800
                )),
                Text("Let contacts add you by scanning this code", style: TextStyle(
                    color: Colors.grey.shade400,
                )),
              ]),
            ),
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10, bottom: 10),
                width: 150, height: 150,
                child: QrImage(
                  version: 1,
                  foregroundColor: Colors.black87,
                  gapless: true,
                  data: clientDto.fullPhoneNumber,
                  size: 200.0,
                ),
              ),
            ),
          ]
      ),
    );
  }

  // Update user settings
  Future<UserSettingsDto> doUpdateUserSettings() async {
    setState(() {
      displaySettingsLoader = true;
    });

    http.Response response = await HttpClientService.post('/api/users/${clientDto.id}/settings', body: clientDto.userSettings);

    await Future.delayed(Duration(milliseconds: 500));

    if (response.statusCode != 200) {
      throw new Exception();
    }

    return UserSettingsDto.fromJson(response.decode());
  }

  onSettingsSuccess(UserSettingsDto userSettings) async {
    this.clientDto.userSettings = userSettings;
    await UserService.setUser(clientDto);

    setState(() {
      displaySettingsLoader = false;
    });
  }

  onSettingsError(error) {
    print(error);

    setState(() {
      displaySettingsLoader = false;
    });
  }

  // Get Profile
  Future<void> doGetProfileData() async {
    var user = await UserService.getUser();
    http.Response response = await HttpClientService.get('/api/users/${user.id}');

    await Future.delayed(Duration(milliseconds: 500));

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

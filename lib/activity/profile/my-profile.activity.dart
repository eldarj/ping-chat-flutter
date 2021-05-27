import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/profile/profile-image-upload/profile-image-upload.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/user-settings.dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/profile/profile.publisher.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/country-icon.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/dialog/generic-alert.dialog.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/info/info.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/modal/floating-modal.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyProfileActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new MyProfileActivityState();
}

class MyProfileActivityState extends BaseState<MyProfileActivity> {
  StateSetter backgroundsModalSetState;

  var displayLoader = true;

  DateFormat dateFormat = DateFormat("dd.MM.yy");
  ClientDto clientDto;
  String createdAtFormatted;

  bool displaySettingsLoader = false;
  bool displayProfileActionsLoader = false;

  List<Color> chatBubbleColors = CompanyColor.messageThemes
      .entries.map<Color>((element) => element.key)
      .toList();

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
    appBar = BaseAppBar.getBackAppBar(getScaffoldContext, titleText: 'Profile');
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
              buildProfileActions(),
            ])
        );
      } else {
        widget = InfoComponent.errorHomer(message: "Couldn't load your profile, please try again", onButtonPressed: () async {
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


  Widget buildSection(title, {text, child, titleLeftMargin: 0.0, IconData icon}) {
    if (child == null && text is int) {
      text = text.toString();
    }
    return Container(
      margin: EdgeInsets.only(left: 12.5, bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon != null ? Container(
              margin: EdgeInsets.only(right: 12.5),
              child: Icon(icon, color: Colors.grey.shade700, size: 20)) : Container(),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                margin: EdgeInsets.only(left: titleLeftMargin, bottom: 5),
                child: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800))
            ),
            child != null ? child : Text(text != null ? text : "")
          ]),
        ],
      ),
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
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [Shadows.bottomShadow()]
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GestureDetector(
            onTap: pushProfileImageUploadActivity,
            child: Container(
                margin: EdgeInsets.only(left: 5, right: 5),
                child: Center(
                  child: Stack(
                    alignment: AlignmentDirectional.bottomEnd,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            boxShadow: [BoxShadow(color: Colors.grey.shade50, blurRadius: 15, spreadRadius: 1)],
                            borderRadius: BorderRadius.all(Radius.circular(20))
                        ),
                        child: new RoundProfileImageComponent(url: clientDto.profileImagePath,
                            height: 200, width: 200, borderRadius: 45),
                      ),
                      Container(
                          margin: EdgeInsets.all(10),
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
                padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(clientDto.firstName + ' ' + clientDto.lastName,
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 29)),
                ]),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: buildTwoColumns([
              buildSection('Phone number',
                  icon: Icons.phone,
                  text: clientDto.countryCode.dialCode + " " + clientDto.phoneNumber),
            ], [
              buildSection('Joined', icon: Icons.verified_user_outlined, text: createdAtFormatted),
            ]),
          ),
          Container(
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 20),
            child: Row(
              children: [
                Container(
                    margin: EdgeInsets.only(right: 15, left: 15),
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

  Widget buildProfileActions() {
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
                    child: Text("Profile", style: TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.grey.shade800
                    )),
                  ),
                  Spinner(size: 20, visible: displayProfileActionsLoader)
                ],
              ),
            ),
            IgnorePointer(
              ignoring: displayProfileActionsLoader || clientDto.profileImagePath == null,
              child: AnimatedOpacity(
                  duration: Duration(milliseconds: 250),
                  opacity: displayProfileActionsLoader || clientDto.profileImagePath == null ? 0.5 : 1,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        var dialog = GenericAlertDialog(
                            title: 'Remove profile photo',
                            message: 'You will not be able to restore your profile photo',
                            onPostivePressed: () {
                              doRemoveProfilePhoto().then(onRemoveProfileSuccess, onError: onRemoveProfileError);
                            },
                            positiveBtnText: 'Remove',
                            negativeBtnText: 'Cancel');
                        showDialog(context: getScaffoldContext(), builder: (BuildContext context) => dialog);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Container(
                                child: Icon(Icons.image_not_supported_outlined, color: Colors.red),
                                margin: EdgeInsets.only(left: 7.5, right: 20),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade50,
                                ),
                              ),
                              Text('Remove profile photo',
                                  style: TextStyle(color: Colors.grey.shade800)),
                            ]),
                            new RoundProfileImageComponent(url: clientDto.profileImagePath,
                                height: 40, width: 40, borderRadius: 100)
                          ],
                        ),
                      ),
                    ),
                  )
              ),
            ),
          ]
      ),
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
                        fontWeight: FontWeight.w500, color: Colors.grey.shade800
                    )),
                  ),
                  Spinner(size: 20, visible: displaySettingsLoader)
                ],
              ),
            ),
            IgnorePointer(
              ignoring: displaySettingsLoader,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 250),
                opacity: displaySettingsLoader ? 0.5 : 1,
                child: Column(children: [
                  buildChatBubbleColorButton(),
                  buildSwitchButton(
                      Icons.vibration,
                      'Vibrate',
                      'Vibrate on new messages',
                      clientDto.userSettings.vibrate,
                      (value) {
                        clientDto.userSettings.vibrate = value;
                        doUpdateUserSettings().then(onSettingsSuccess, onError: onSettingsError);
                      }),
                  buildSwitchButton(
                      Icons.notifications_none,
                      'Notifications',
                      'Receive incoming notifications',
                      clientDto.userSettings.receiveNotifications,
                          (value) {
                        clientDto.userSettings.receiveNotifications = value;
                        doUpdateUserSettings().then(onSettingsSuccess, onError: onSettingsError);
                      }),
                  buildSwitchButton(
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

  buildChatBubbleColorButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showCustomModalBottomSheet(context: context,
              containerWidget: (_, animation, child) => FloatingModal(
                child: child,
                maxHeight: DEVICE_MEDIA_SIZE.height - 100,
              ),
              builder: buildBackgroundModal
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    child: Icon(Icons.chat_outlined, color: Colors.grey.shade700),
                    margin: EdgeInsets.only(left: 7.5, right: 20),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade50,
                    ),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chat color',
                          style: TextStyle(color: Colors.grey.shade800)),
                      Text('Change your chat bubbles color',
                          style: TextStyle(color: Colors.grey.shade400))
                    ],
                  ),
                ]),
                Container(
                  padding: EdgeInsets.all(2.5),
                  margin: EdgeInsets.only(left: 10, right: 10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Container(
                  height: 25, width: 25, color: clientDto.userSettings.chatBubbleColorHex == null
                      ? CompanyColor.myMessageBackground
                      : CompanyColor.fromHexString(clientDto.userSettings.chatBubbleColorHex)),
                ),
              ]
          ),
        ),
      ),
    );
  }

  buildSwitchButton(icon, text, description, value, onChanged) {
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
                    fontWeight: FontWeight.w500, color: Colors.grey.shade800
                )),
                Text("Let contacts add you by scanning your QR Code", style: TextStyle(
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

  Widget buildBackgroundModal(BuildContext context)  {
    return StatefulBuilder(
        builder: (context, setState) {
          backgroundsModalSetState = setState;
          return Container(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Column(children: [
                Container(
                  margin: EdgeInsets.only(left: 20, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(margin: EdgeInsets.only(right: 10),
                              width: 45, height: 45,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.0),
                                  color: Colors.grey.shade50
                              ),
                              child: Icon(Icons.chat_outlined, color: Colors.grey.shade700, size: 20)),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Chat color',
                                style: TextStyle(color: Colors.grey.shade800)),
                            Text('Change your chat bubbles color',
                                style: TextStyle(color: Colors.grey.shade400))
                          ]),
                        ],
                      ),
                      CloseButton(onPressed: () async {
                        Navigator.of(context).pop();
                      })
                    ],
                  ),
                ),
                Divider(height: 25, thickness: 1),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(bottom: 20),
                    margin: EdgeInsets.only(left: 20, right: 20),
                    child: Align(
                      child: Opacity(
                        opacity: displaySettingsLoader ? 0.2 : 1,
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisSpacing: 10, mainAxisSpacing: 10, crossAxisCount: 2),
                          itemCount: chatBubbleColors.length,
                          itemBuilder: (context, index) {
                            var backgroundWidth = DEVICE_MEDIA_SIZE.width / 2 - 50;
                            return Align(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      clientDto.userSettings.chatBubbleColorHex = CompanyColor.toHexString(chatBubbleColors[index]);
                                      doUpdateUserSettings().then(onSettingsSuccess, onError: onSettingsError);
                                    },
                                    child: Container(
                                        padding: EdgeInsets.all(5),
                                        height: backgroundWidth * 3,
                                        width: backgroundWidth,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.white),
                                            borderRadius: BorderRadius.circular(5),
                                            boxShadow: [BoxShadow(color: Colors.grey.shade50,
                                              offset: Offset.fromDirection(1, 0.7),
                                              blurRadius: 5, spreadRadius: 5,
                                            )]
                                        ),
                                        child: Container(
                                          color: chatBubbleColors[index]
                                        )),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                )
              ])
          );
        }
    );
  }

  // Update user settings
  Future<UserSettingsDto> doUpdateUserSettings() async {
    setState(() {
      displaySettingsLoader = true;
    });

    if (backgroundsModalSetState != null) {
      backgroundsModalSetState(() {});
    }

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

  // Remove user profile
  Future doRemoveProfilePhoto() async {
    setState(() {
      displayProfileActionsLoader = true;
    });

    var user = await UserService.getUser();
    await Future.delayed(Duration(seconds: 1));

    var response = await HttpClientService.delete('/api/users/${user.id}/profile-image');

    if (response.statusCode != 200) {
      throw new Exception();
    }

    return;
  }

  void onRemoveProfileSuccess(_) async {
    clientDto.profileImagePath = null;
    await UserService.setUser(clientDto);

    setState(() {
      displayProfileActionsLoader = false;
    });
  }

  void onRemoveProfileError(error) {
    print(error);
    setState(() {
      displayProfileActionsLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(
      duration: Duration(seconds: 2)
    ));
  }
}

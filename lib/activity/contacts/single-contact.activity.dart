import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/profile/profile-image-upload/profile-image-upload.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/country-icon.component.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/drawer/partial/drawer-items.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class SingleContactActivity extends StatefulWidget {
  final ContactDto contactDto;

  const SingleContactActivity({ Key key, this.contactDto }) : super(key: key);

  @override
  State<StatefulWidget> createState() => new SingleContactActivityState();
}

class SingleContactActivityState extends BaseState<SingleContactActivity> {
  ScrollController scrollController = new ScrollController();

  bool maximizeProfilePhoto = true;

  bool sharedDataSpaceLoading = true;

  @override
  initState() {
    super.initState();
    scrollController.addListener(() async {
      if (scrollController.position.pixels == 0) {
        setState(() {
          maximizeProfilePhoto = true;
        });
      } else if (maximizeProfilePhoto == true) {
        setState(() {
          maximizeProfilePhoto = false;
        });
      }
    });
  }

  @override
  dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar.getBackAppBar(getScaffoldContext, titleText: widget.contactDto.contactName),
      body: Builder(builder: (context) {
        scaffold = Scaffold.of(context);
        return Container(
          child: buildActivityContent(),
        );
      }),
    );
  }

  Widget buildActivityContent() {
    Widget _w = Center(child: Spinner());
    if (!displayLoader) {
      if (!isError) {
        _w = Container(
            child: ListView(controller: scrollController, children: [
              Container(
                  padding: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Colors.white
                  ),
                  child: Column(children: [
                    Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        Row(children: [
                          Container(height: 250, width: DEVICE_MEDIA_SIZE.width, color: CompanyColor.bluePrimary)
                        ]),
                        Container(
                          height: 350,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              AnimatedContainer(
                                duration: Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                margin: EdgeInsets.only(bottom: maximizeProfilePhoto ? 0 : 50),
                                height: maximizeProfilePhoto ? 350 : 200,
                                width: maximizeProfilePhoto ? DEVICE_MEDIA_SIZE.width : 200,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.white, width: maximizeProfilePhoto ? 0 : 3),
                                  borderRadius: BorderRadius.circular(maximizeProfilePhoto ? 0 : 32.5),
                                ),
                                child: ClipRRect(borderRadius: BorderRadius.circular(maximizeProfilePhoto ? 0 : 30),
                                  child: CachedNetworkImage(imageUrl: widget.contactDto.contactUser?.profileImagePath, fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                          margin: EdgeInsets.all(15),
                                          child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.grey.shade100))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ])
              ),
              Container(
                  padding: EdgeInsets.only(top: 10, bottom: 25),
                  color: Colors.white,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                        margin: EdgeInsets.only(right: 25),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: CompanyColor.bluePrimary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: GestureDetector(
                            onTap: () {},
                            child: Container(child: Icon(Icons.chat, color: Colors.white))
                        )
                    ),
                    Container(
                        margin: EdgeInsets.only(left: 25),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: CompanyColor.bluePrimary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: GestureDetector(
                            onTap: () {},
                            child: Container(child: Icon(Icons.phone, color: Colors.white))
                        )
                    ),
                  ])),
              Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                      boxShadow: [Shadows.bottomShadow()]
                  ),
                  child: buildTwoColumns([
                    buildDrawerItem(context, 'Broj telefona',
                        buildIcon(icon: Icons.phone_android, backgroundColor: Colors.green.shade400,
                            size: 20, iconSize: 10),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15),
                        labelDescription: widget.contactDto.contactPhoneNumber),
                  ], [
                    buildDrawerItem(context, widget.contactDto.contactUser?.countryCode.countryName,
                        CountryIconComponent.buildCountryIcon(
                            widget.contactDto.contactUser?.countryCode.countryName, height: 15, width: 15
                        )),
                  ])
              ),
              Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                      boxShadow: [Shadows.bottomShadow()]
                  ),
                  child: Column(children: [
                    buildSectionHeader('Djeljeni medij'),

                  ])),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Theme.of(context).backgroundColor,
                    boxShadow: [Shadows.bottomShadow()]
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FlatButton(onPressed: () {}, child: Row(children: [
                    Container(
                        margin: EdgeInsets.only(right: 10),
                        child: Icon(Icons.photo_library, color: Colors.grey.shade700)),
                    Text('Pozadina', style: TextStyle(color: Colors.grey.shade700))
                  ]))
                ]),
              ),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Theme.of(context).backgroundColor,
                    boxShadow: [Shadows.bottomShadow()]
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      !widget.contactDto.favorite ? FlatButton(onPressed: () {}, child: Row(
                        children: <Widget>[
                          Container(
                              margin: EdgeInsets.only(right: 10),
                              child: Icon(Icons.star, color: Colors.yellow.shade700)),
                          Text('Dodaj u omiljene', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      )) : FlatButton(onPressed: () {}, child: Row(
                        children: <Widget>[
                          Container(
                              margin: EdgeInsets.only(right: 10),
                              child: Icon(Icons.star_border, color: Colors.yellow.shade700)),
                          Text('Ukloni iz omiljenih', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ))
                    ]),
              ),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Theme.of(context).backgroundColor,
                    boxShadow: [Shadows.bottomShadow()]
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FlatButton(onPressed: () {}, child: Text('Izbriši kontakt', style: TextStyle(color: CompanyColor.red))),
                      FlatButton(onPressed: () {}, child: Text('Blokiraj kontakt', style: TextStyle(color: CompanyColor.red))),
                      FlatButton(onPressed: () {}, child: Text('Izbriši sve poruke', style: TextStyle(color: CompanyColor.red))),
                    ]),
              )
            ])
        );
      } else {
        _w = ErrorComponent.build(actionOnPressed: () async {
          scaffold.removeCurrentSnackBar();
          setState(() {
            displayLoader = true;
            isError = false;
          });

          // doGetProfileData().then(onGetProfileDataSuccess, onError: onGetProfileDataError);
        });
      }
    }

    return _w;
  }

  Widget buildSectionHeader(title, { icon }) {
    return Container(
        padding: EdgeInsets.only(top: 20, left: 5, bottom: 10),
        margin: EdgeInsets.only(left: 5, bottom: 10),
        child: Row(children: [
          Container(
              margin: EdgeInsets.only(right: 5),
              child: icon != null ? Icon(icon, size: 25) : Container()),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
        ]));
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
}

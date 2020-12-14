import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/profile/profile-image-upload/profile-image-upload.activity.dart';
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
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/base/base.state.dart';
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
  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    setState(() {
      this.displayLoader = false;
    });
  }

  @override
  preRender() {
    appBar = BaseAppBar.getBackAppBar(getScaffoldContext, titleText: 'Kontakt');
    drawer = new NavigationDrawerComponent();
  }

  @override
  Widget render() {
    return buildActivityContent();
  }

  Widget buildActivityContent() {
    Widget contentWidget = Center(child: Spinner());
    if (!displayLoader) {
      if (!isError) {
        contentWidget = Container(
            child: ListView(children: [
              Container(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  decoration: BoxDecoration(
                      color: Colors.white
                  ),
                  child: Column(children: [
                    Row(children: [
                      Container(
                          margin: EdgeInsets.only(left: 5, right: 10),
                          child: new RoundProfileImageComponent(url: widget.contactDto.contactUser?.profileImagePath,
                              height: 100, width: 100, borderRadius: 20)
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          "Pozdrav,",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 24),
                        ),
                        Text(widget.contactDto.contactName,
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 27)),
                      ]),
                    ]),
                    Container(
                        margin: EdgeInsets.only(left: 10, top: 10),
                        child: buildTwoColumns([
                          buildSection('Broj telefona', text: widget.contactDto.contactPhoneNumber),
                        ], [
                          buildSection('Račun kreiran', text: 'createdAtFormatted'),
                        ])
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 20, bottom: 10),
                      child: Row(
                        children: <Widget>[
                          Container(
                              margin: EdgeInsets.only(right: 10, left: 1),
                              child: CountryIconComponent
                                  .buildCountryIcon(widget.contactDto.contactUser?.countryCode.countryName, height: 15, width: 15)
                          ),
                          Container(
                              child: Text(widget.contactDto.contactUser?.countryCode.countryName)
                          )
                        ],
                      ),
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
                      buildSectionHeader('Media & Storage', icon: Icons.image),
                      buildTwoColumns([
                        buildSection('Izdavalac', text: 'widget.contactDto.drivingLicenceIssuedFrom'),
                      ], [
                        buildSection('Datum izdavanja', text: 'widget.contactDto.drivingLicenceDate'),
                      ]),

                      buildSectionHeader('Sačuvano', icon: Icons.bookmark_border),
                      buildTwoColumns([
                        buildSection('Godište', text: 'widget.contactDto.car.year'),
                      ], [
                        buildSection('Opcije', child: Text('CarOptionsComponent(options: jsonDecode(widget.contactDto.car.options))')),
                      ]),

                      buildSectionHeader('Favourite contacts', icon: Icons.star_border),
                      buildTwoColumns([
                        buildSection('Oznaka licence', text: 'widget.contactDto.taxiLicenceNumber'),
                      ], [
                        buildSection('Datum izdavanja', text: 'getFormattedDate(widget.contactDto.taxiLicenceDate)'),
                      ]),
                    ]
                ),
              )
            ])
        );
      } else {
        contentWidget = ErrorComponent.build(actionOnPressed: () async {
          scaffold.removeCurrentSnackBar();
          setState(() {
            displayLoader = true;
            isError = false;
          });

          // doGetProfileData().then(onGetProfileDataSuccess, onError: onGetProfileDataError);
        });
      }
    }

    return contentWidget;
  }


  Widget buildSectionHeader(title, { icon }) {
    return Container(
        padding: EdgeInsets.only(top: 20, left: 5, bottom: 10),
        margin: EdgeInsets.only(left: 5, bottom: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(
          width: 1, color: Colors.grey.shade300,
        ))),
        child: Row(children: [
          Container(
              margin: EdgeInsets.only(right: 5),
              child: icon != null ? Icon(icon, size: 25) : Container()),
          Text(title, style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold))
        ]));
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
}

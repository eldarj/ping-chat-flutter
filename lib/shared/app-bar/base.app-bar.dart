import 'package:flutter/material.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';

const double APP_BAR_ELEVATION = 1.5;
const Color APP_BAR_SHADOW_COLOR = Color.fromRGBO(0, 0, 0, 0.5);

class BaseAppBar {
  static getBase(Function getContext, {
    leading, titleWidget, titleText = '', actions, centerTitle = true, double elevation = APP_BAR_ELEVATION
  }) {
    return AppBar(
        elevation: elevation,
        shadowColor: APP_BAR_SHADOW_COLOR,
        centerTitle: centerTitle,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          leading,
          titleWidget != null ? Expanded(child: titleWidget) : Text(titleText)
        ]),
        actions: actions);
  }

  static _backPressed(Function getContext) {
    Navigator.pop(getContext());
  }

  static getBackAppBar(Function getContext, {
    titleWidget, titleText = '', actions, centerTitle = true, Function onBackPressed = _backPressed,
  }) {
    return getBase(getContext,
        leading: BackButton(onPressed: () async {
          await Future.delayed(Duration(milliseconds: 250));
          onBackPressed(getContext);
        }),
        titleText: titleText, titleWidget: titleWidget, actions: actions, centerTitle: centerTitle);
  }

  static getCloseAppBar(Function getContext, {
    titleWidget, titleText = '', actions, centerTitle = true, Function onBackPressed = _backPressed,
  }) {
    return getBase(getContext,
        elevation: 0.0,
        leading: CloseButton(onPressed: () async {
          await Future.delayed(Duration(milliseconds: 250));
          onBackPressed(getContext);
        }),
        titleText: titleText, titleWidget: titleWidget, actions: actions, centerTitle: centerTitle);
  }

  static getProfileAppBar(ScaffoldState scaffold, {
    titleWidget, titleText, actions, bottomTabs, centerTitle = true
  }) {
    return AppBar(
        elevation: APP_BAR_ELEVATION,
        shadowColor: APP_BAR_SHADOW_COLOR,
        centerTitle: centerTitle,
        backgroundColor: Colors.white,
        bottom: bottomTabs,
        leadingWidth: 70,
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              scaffold.openDrawer();
            },
            child: Container(
                alignment: Alignment.center,
                child: FutureBuilder(future: UserService.getUser(), builder: (context, snapshot) {
                  return snapshot.hasData ? RoundProfileImageComponent(url: snapshot.data.profileImagePath,
                      height: 40, width: 40, margin: 0) : Spinner();
                })
            ),
          ),
        ),
        title: titleText != null ? Text(titleText) : titleWidget,
        actions: actions);
  }
}

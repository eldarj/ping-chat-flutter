import 'package:flutter/material.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';

class BaseAppBar {
  static getBase(Function getContext, {leading, titleWidget, titleText = '', actions, centerTitle = true
  }) {
    return AppBar(
        elevation: 0.0,
        centerTitle: centerTitle,
        backgroundColor: Colors.grey.shade50,
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
    titleWidget, titleText = '', actions, centerTitle = true, Function onBackPressed = _backPressed }) {
    return getBase(getContext,
        leading: BackButton(onPressed: () async {
          await Future.delayed(Duration(milliseconds: 250));
          onBackPressed(getContext);
        }),
        titleText: titleText, titleWidget: titleWidget, actions: actions, centerTitle: centerTitle);
  }

  static getCloseAppBar(Function getContext, {
    titleWidget, titleText = '', actions, centerTitle = true, Function onBackPressed = _backPressed }) {
    return getBase(getContext,
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
        elevation: 0.0,
        centerTitle: centerTitle,
        backgroundColor: Colors.grey.shade50,
        bottom: bottomTabs,
        leading: GestureDetector(
          onTap: () {
            scaffold.openDrawer();
          },
          child: Container(
              margin: EdgeInsets.only(left: 10),
              alignment: Alignment.center,
              child: Stack(
                  alignment: AlignmentDirectional.bottomEnd,
                  children: [
                    Container(alignment: Alignment.center,
                        width: 45, height: 45,
                        child: FutureBuilder(future: UserService.getUser(), builder: (context, snapshot) {
                          return snapshot.hasData ? RoundProfileImageComponent(url: snapshot.data.profileImagePath,
                              height: 40, width: 40, margin: 0) : Spinner();
                        })
                    ),
                    Container(alignment: Alignment.center,
                        width: 17.5, height: 17.5,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 0.5, spreadRadius: 0.2)]
                        ),
                        child: Icon(Icons.menu, size: 15, color: CompanyColor.blueDark))
                  ]
              )
          ),
        ),
        title: titleText != null ? Text(titleText) : titleWidget,
        actions: actions);
  }
}

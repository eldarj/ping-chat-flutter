import 'package:flutter/material.dart';
import 'package:flutterping/service/user.prefs.service.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';

class BaseAppBar {
  static getBase(ScaffoldState scaffold, leading, {
    titleWidget, titleText, actions
  }) {
    return AppBar(
        elevation: 0.0,
        centerTitle: true,
        backgroundColor: CompanyColor.backgroundGrey,
        leading: leading,
        title: titleText != null ? Text(titleText) : titleWidget,
        actions: actions);
  }

  static getBackAppBar(ScaffoldState scaffold, {
    titleWidget, titleText, actions
  }) {
    return getBase(scaffold, FlatButton(
      onPressed: () {
        Navigator.pop(scaffold.context);
      },
      child: Icon(Icons.arrow_back),
    ), titleText: titleText, titleWidget: titleWidget, actions: actions);
  }

  static getProfileAppBar(ScaffoldState scaffold, {
    titleWidget, titleText, actions, bottomTabs
  }) {
    return AppBar(
        elevation: 0.0,
        centerTitle: true,
        backgroundColor: CompanyColor.backgroundGrey,
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
                          return snapshot.hasData
                              ? CircleAvatar(backgroundImage: NetworkImage(snapshot.data.profileImagePath))
                              : Spinner();
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

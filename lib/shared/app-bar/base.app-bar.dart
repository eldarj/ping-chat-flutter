
import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

class BaseAppBar {
  static getBase(ScaffoldState scaffold, leading, {
    titleWidget, titleText, actions
  }) {
    return AppBar(
        elevation: 0.0,
        centerTitle: true,
        backgroundColor: Colors.grey.shade200,
        leading: leading,
        title: titleText != null ? Text(titleText) : titleWidget,
        actions: actions);
  }

  static getProfileAppBar(ScaffoldState scaffold, {
    titleWidget, titleText, actions
  }) {
    return AppBar(
        elevation: 0.0,
        centerTitle: true,
        backgroundColor: Colors.grey.shade200,
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
                        child: CircleAvatar(backgroundImage: NetworkImage("https://media-exp1.licdn.com/dms/image/C5603AQH9KNis_BzaRA/profile-displayphoto-shrink_100_100/0?e=1608768000&v=beta&t=-A__OpLiqt5XbBcRDSoDJdgOjsUszXHJzxhkp8jTMrs"))
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

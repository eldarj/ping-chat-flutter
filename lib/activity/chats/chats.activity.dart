
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/util/base/base.state.dart';

class ChatsActivity extends StatefulWidget {
  const ChatsActivity();

  @override
  State<StatefulWidget> createState() => new ChatsActivityState();
}

class ChatsActivityState extends BaseState<ChatsActivity> {
  @override
  preRender() {
    appBar = BaseAppBar.getBase(scaffold, NavigationDrawerLeading.build(() {
      scaffold.openDrawer(); }),
        titleText: 'Chats');

    BottomNavigationComponent createState = new BottomNavigationComponent(currentIndex: 0);
    bottomNavigationBar = createState.build(context);
  }

  @override
  Widget render() {
    return Center(
        child: Container(
          width: 300,
          child: Text('Chats'),
        ));
  }
}

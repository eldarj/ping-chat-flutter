

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  ScaffoldState scaffold;
  bool displayLoader = false;

  AppBar appBar;

  BottomNavigationBar bottomNavigationBar;

  var drawer;

  @override
  Widget build(BuildContext context) {
    preRender();

    return Scaffold(
        appBar: appBar != null ? appBar : null,
        bottomNavigationBar: bottomNavigationBar != null ? bottomNavigationBar : null,
        drawer: drawer != null ? drawer : null,
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return this.render();
        })
    );
  }

  Widget render();

  preRender() {}
}

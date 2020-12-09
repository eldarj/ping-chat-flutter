

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  ScaffoldState scaffold;
  bool displayLoader = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return this.render();
        })
    );
  }

  @protected
  Widget render();
}

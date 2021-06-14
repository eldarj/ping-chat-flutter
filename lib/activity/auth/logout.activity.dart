import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/linear-progress-loader.component.dart';

class LogoutActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new LogoutActivityState();
}

class LogoutActivityState extends State<LogoutActivity> {
  ScaffoldState scaffold;

  bool displayLoader = true;

  @override
  void initState() {
    doLogout();
    super.initState();
  }

  doLogout() async {
    await UserService.remove();
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      displayLoader = false;
    });

    scaffold.showSnackBar(SnackBarsComponent.success('You logged out.'));

    await Future.delayed(Duration(seconds: 1));
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return Container(
              alignment: Alignment.topLeft,
              color: Colors.white,
              child: Container(
                child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(margin: EdgeInsets.only(bottom: 25, right: 15), child: Text(":-(", style: TextStyle(
                              fontSize: 70,
                              color: Colors.black87,
                            ))),
                            Text("We're logging you out, please wait."),
                          ],
                        ),
                      ),
                      Opacity(
                          opacity: displayLoader ? 1 : 0,
                          child: LinearProgressLoader.build(context)
                      )]),
              ));
        }));
  }
}

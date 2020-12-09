import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/landing/policy.activity.dart';
import 'package:flutterping/shared/component/linear-progress-loader.component.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class LandingActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LandingActivityState();
}

class _LandingActivityState extends BaseState<LandingActivity> {
  @override
  void initState() {
    super.initState();
    loadActivity();
  }

  loadActivity() async {
    await Future.delayed(Duration(seconds: 2));
    NavigatorUtil.replace(context, PolicyActivity());
  }

  @override
  Widget render() {
    return Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [CompanyColor.blueAccent, CompanyColor.blueDark])),
        child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                child: Container(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    LogoComponent.build(orientation: LogoOrientation.vertical, fontSize: 60,
                        whiteFace: true,
                        textColor: Colors.white)
                  ]),
                ),
              ),
              LinearProgressLoader.build(context)
            ]))
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/auth/login.activity.dart';
import 'package:flutterping/activity/landing/signup-form.activity.dart';
import 'package:flutterping/activity/landing/landing.activity.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/component/linear-progress-loader.component.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class PolicyActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new PolicyActivityState();
}

class PolicyActivityState extends BaseState<PolicyActivity> {
  bool displayLoader = false;

  @override
  Widget render() {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: FutureBuilder(builder: (context, snapshot) {
          scaffold = Scaffold.of(context);
          return Container(
              alignment: Alignment.topLeft,
              color: Colors.white,
              child: Container(
                child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                                child: LogoComponent.build(orientation: LogoOrientation.vertical, displayText: false)),
                            Container(
                                width: 300,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text('Molimo pročitajte policy, te pritisnite "Prihvatam" da započnete koristiti aplikaciju.', textAlign: TextAlign.center),
                                    Container(
                                        margin: EdgeInsets.all(50),
                                        child: GradientButton(
                                            child: Text('Prihvatam'),
                                            onPressed: displayLoader ? null : onAcceptPolicy)
                                    )
                                  ],
                                )
                            )
                          ],
                        ),
                      ),
                      Opacity(opacity: displayLoader ? 1 : 0, child: LinearProgressLoader.build(context))]),
              ));
        }));
  }

  onAcceptPolicy() async {
    setState(() {
      displayLoader = true;
    });
    await Future.delayed(Duration(seconds: 3));
    NavigatorUtil.replace(context, LoginActivity());
  }
}

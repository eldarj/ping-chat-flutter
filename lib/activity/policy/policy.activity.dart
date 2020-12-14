import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/auth/login.activity.dart';
import 'package:flutterping/activity/policy/policy-info.activity.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/loader/linear-progress-loader.component.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class PolicyActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new PolicyActivityState();
}

class PolicyActivityState extends BaseState<PolicyActivity> {
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(bottom: 5),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Text("Please read the "),
                                        GestureDetector(
                                          onTap: () {
                                            NavigatorUtil.push(context, PolicyInfoActivity());
                                          },
                                          child: Text("Terms of Services and Privacy Policy", style: TextStyle(
                                            color: Colors.blue, decoration: TextDecoration.underline, // TODO: add info activity
                                          )),
                                        ),
                                      ]),
                                    ),
                                    Text('and hit "Accept" to start using the application.'),
                                    Container(
                                        margin: EdgeInsets.all(25),
                                        child: GradientButton(
                                            child: Text('Accept'),
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
    NavigatorUtil.replace(context, LoginActivity());
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/auth/login.activity.dart';
import 'package:flutterping/activity/policy/policy-info.activity.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/loader/linear-progress-loader.component.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:permission_handler/permission_handler.dart';

class PolicyActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new PolicyActivityState();
}

class PolicyActivityState extends BaseState<PolicyActivity> {
  @override
  Widget render() {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: FutureBuilder(builder: (context, snapshot) {
          scaffold = Scaffold.of(context);
          return Container(
              color: Colors.white,
              alignment: Alignment.topLeft,
              child: Container(
                child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(child: LogoComponent.logo),
                            Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(top: 25, bottom: 5),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Text("Please read the "),
                                        GestureDetector(
                                          onTap: () {
                                            NavigatorUtil.push(context, PolicyInfoActivity());
                                          },
                                          child: Text("Terms of Services and Privacy Policy", style: TextStyle(
                                            color: Colors.blue, decoration: TextDecoration.underline,
                                          )),
                                        ),
                                      ]),
                                    ),
                                    Text('and hit "Accept" to start using the application.'),
                                    Container(
                                        margin: EdgeInsets.all(25),
                                        child: GradientButton(
                                            child: displayLoader
                                                ? Container(height: 20, width: 20, child: Spinner())
                                                : Text('Accept'),
                                            onPressed: displayLoader ? null : onAcceptPolicy)
                                    )
                                  ],
                                )
                            )
                          ],
                        ),
                      ),
                    ]),
              ));
        }));
  }

  onAcceptPolicy() async {
    setState(() {
      displayLoader = true;
    });

    await initPermissions();
    await Future.delayed(Duration(milliseconds: 500));

    NavigatorUtil.replace(context, LoginActivity());
  }


  initPermissions() async {
    await Permission.microphone.request();
    await Permission.contacts.request();
  }
}

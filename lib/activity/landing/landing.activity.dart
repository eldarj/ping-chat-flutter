import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/activity/policy/policy.activity.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/shared/loader/linear-progress-loader.component.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/widget/base.state.dart';

class LandingActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LandingActivityState();
}

class LandingActivityState extends BaseState<LandingActivity> {
  @override
  void initState() {
    super.initState();
    loadActivity();
  }

  loadActivity() async {
    var isUserLoggedIn = await UserService.isUserLoggedIn();

    setState(() {
      displayLoader = true;
    });

    if (isUserLoggedIn) {
      await Future.delayed(Duration(seconds: 1));
      NavigatorUtil.replace(context, ChatListActivity());
    } else {
      await Future.delayed(Duration(seconds: 3));
      NavigatorUtil.replace(context, PolicyActivity());
    }
  }

  @override
  Widget render() {
    return Container(
        color: Colors.white,
        child: Center(
            child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LogoComponent.vertical
                          ]
                      ),
                    ),
                  ),
                  displayLoader ? LinearProgressLoader.build(context) : Container()
                ]
            )
        )
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterping/activity/landing/landing.activity.dart';
import 'package:sip_ua/sip_ua.dart';

import 'activity/callscreen.dart';
import 'activity/dialpad.dart';
import 'activity/register.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    SIPUAHelper helper = new SIPUAHelper();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ping',
        initialRoute: '/landing',
        routes: {
          '/': (context) => DialPadWidget(helper),
          '/landing': (context) => LandingActivity(),
          '/register': (context) => RegisterWidget(helper)
        },
        theme: ThemeData(
          fontFamily: 'Roboto',
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        )
    );
  }
}

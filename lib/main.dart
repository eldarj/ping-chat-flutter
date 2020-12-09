import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterping/activity/chats/chats.activity.dart';
import 'package:flutterping/activity/landing/landing.activity.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ping',
        initialRoute: '/',
        routes: {
          '/': (context) => LandingActivity()
        },
        theme: ThemeData(
          fontFamily: 'Roboto',
          primarySwatch: Colors.lightBlue,
        )
    );
  }
}

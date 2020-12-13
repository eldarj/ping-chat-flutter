import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/activity/contacts/add-contact.activity.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/activity/landing/landing.activity.dart';
import 'package:flutterping/activity/policy/policy.activity.dart';
import 'package:flutterping/activity/profile/my-profile.activity.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    var themeData = ThemeData(
      fontFamily: 'Roboto',
      primarySwatch: Colors.lightBlue,
      backgroundColor: Colors.white,
    );

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ping',
        initialRoute: '/',
        routes: {
          '/': (context) => LandingActivity()
        },
        theme: themeData,
        builder: (context, child) => StreamChat(
          streamChatThemeData: StreamChatThemeData.fromTheme(themeData),
          child: child,
        )
    );
  }
}

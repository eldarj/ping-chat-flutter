import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterping/activity/chats/chats.activity.dart';
import 'package:flutterping/activity/contacts/add-contact.activity.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/activity/landing/landing.activity.dart';
import 'package:flutterping/activity/policy/policy.activity.dart';
import 'package:flutterping/activity/profile/my-profile.activity.dart';

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
          '/': (context) => ContactsActivity()
        },
        theme: ThemeData(
          fontFamily: 'Roboto',
          primarySwatch: Colors.lightBlue,
          backgroundColor: Colors.white,
        )
    );
  }
}

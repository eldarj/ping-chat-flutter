import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/activity/contacts/add-contact.activity.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/activity/landing/landing.activity.dart';
import 'package:flutterping/activity/policy/policy.activity.dart';
import 'package:flutterping/activity/profile/my-profile.activity.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';

void main() {
  runApp(MyApp());
  wsClientService.receivingMessagesPub.addListener("ROOT_LEVEL_LISTENER", (message) {
    sendReceivedStatus(new MessageSeenDto(id: message.id,
        senderPhoneNumber: message.sender.countryCode.dialCode + message.sender.phoneNumber));
  });
}

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
        theme: themeData
    );
  }
}

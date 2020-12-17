import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutterping/activity/landing/landing.activity.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';

void main() {
  runApp(MyApp());

  initializeFlutterDownloader();
  initializeReceivingMessagesListener();
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

initializeFlutterDownloader() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
}

initializeReceivingMessagesListener() {
  wsClientService.receivingMessagesPub.addListener("ROOT_LEVEL_LISTENER", (message) {
    sendReceivedStatus(new MessageSeenDto(id: message.id,
        senderPhoneNumber: message.sender.countryCode.dialCode + message.sender.phoneNumber));
  });
}

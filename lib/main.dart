import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutterping/activity/landing/landing.activity.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/dropdown-banner/dropdown-banner.component.dart';

void main() {
  runApp(MyApp());
  initializeFlutterDownloader();
}

Size DEVICE_MEDIA_SIZE;

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
        home: Scaffold(
            body: Builder(builder: (context) {
              DEVICE_MEDIA_SIZE = MediaQuery.of(context).size;
              return LandingActivity();
            })
        ),
        debugShowCheckedModeBanner: false,
        title: 'Ping',
        // initialRoute: '/',
        // routes: {
        //   '/': (context) => LandingActivity()
        // },
        theme: themeData
    );
  }
}

initializeFlutterDownloader() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
}

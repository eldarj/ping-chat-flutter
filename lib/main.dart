import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutterping/activity/calls/callscreen.activity.dart';
import 'package:flutterping/activity/landing/landing.activity.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/voice/call-state.publisher.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/dropdown-banner/dropdown-banner.component.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:sip_ua/sip_ua.dart';

void main() {
  runApp(MyApp());
  initializeFlutterDownloader();
}

Size DEVICE_MEDIA_SIZE;

BuildContext ROOT_CONTEXT;

class MyApp extends StatelessWidget {
  bool initialized = false;

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
              if (!initialized) {
                initialized = true;
                initializeCallHandler();
              }
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

initializeCallHandler() async {
  callStatePublisher.addListener('main', (CallEvent callEvent) {
    var call = callEvent.call;
    var callState = callEvent.callState;

    print('DIRECTION ' + call.direction);

    if (callState.state == CallStateEnum.CALL_INITIATION && call.direction == 'INCOMING') {
      NavigatorUtil.push(ROOT_CONTEXT, new CallScreenWidget(
        target: '+xxx',
        contactName: '===',
        fullPhoneNumber: 'Phone',
        direction: 'INCOMING',
        incomingCall: call,
      ));
    }
  });
}

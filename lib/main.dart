import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutterping/activity/calls/callscreen.activity.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/service/voice/call-state.publisher.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:sip_ua/sip_ua.dart';

void main() {
  runApp(MyApp());
  initializeFlutterDownloader();
}

// Device size
Size DEVICE_MEDIA_SIZE;

// Root ctx
BuildContext ROOT_CONTEXT;

// Audio player
AudioPlayer _audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
AudioCache  _audioCache = AudioCache(fixedPlayer: _audioPlayer, prefix: 'static/sound/');
bool _playingMessageSound = false;

playMessageSound() async {
  if (!_playingMessageSound) {
    _playingMessageSound = true;
    await _audioCache.play('message-sound-2.mp3');
    _playingMessageSound = false;
  }
}

// Main app
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
      title: 'Ping',
      theme: themeData,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: Builder(builder: (context) {
            if (!initialized) {
              initialized = true;
              initializeCallHandler();
            }
            DEVICE_MEDIA_SIZE = MediaQuery.of(context).size;
            return ChatListActivity();
          })
      ),
    );
  }
}

// Downloader
initializeFlutterDownloader() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
}

// Calls
initializeCallHandler() async {
  callStatePublisher.addListener('main', (CallEvent callEvent) {
    var call = callEvent.call;
    var callState = callEvent.callState;

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

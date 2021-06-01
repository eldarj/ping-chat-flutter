import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
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
EdgeInsets DEVICE_MEDIA_PADDING;

// Root ctx
BuildContext ROOT_CONTEXT;

int CURRENT_OPEN_CONTACT_BINDING_ID = 0;

// Audio player
AudioPlayer _audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
AudioCache  _audioCache = AudioCache(fixedPlayer: _audioPlayer, prefix: 'static/sound/');
bool _playingMessageSound = false;

playMessageSound() async {
  if (!_playingMessageSound) {
    _playingMessageSound = true;
    await _audioCache.play('message-sound-3.mp3');
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
      primarySwatch: CompanyColor.blueDarkMaterial,
      backgroundColor: Colors.white,
      brightness: Brightness.light,
      accentColorBrightness: Brightness.light,
      primaryColorBrightness: Brightness.light,
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
            DEVICE_MEDIA_PADDING = MediaQuery.of(context).padding;
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
  callStatePublisher.addListener('main', (CallEvent callEvent) async {
    var call = callEvent.call;

      if (callEvent.callState.state == CallStateEnum.CALL_INITIATION && call.direction == 'INCOMING') {
        String contactPhoneNumber = call.remote_display_name.replaceAll('Extension', '');
        String url = '/api/contacts/$contactPhoneNumber';

        http.Response response = await HttpClientService.get(url);

        ContactDto contact = ContactDto.fromJson(response.decode());
        ClientDto user = await UserService.getUser();

        if(response.statusCode == 200) {
          NavigatorUtil.push(ROOT_CONTEXT, new CallScreenWidget(
            contact: contact,
            myContactName: user.firstName,
            direction: 'INCOMING',
            incomingCall: call,
          ));
        }
      }
  });
}

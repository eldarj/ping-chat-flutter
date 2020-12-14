
import 'dart:async';
import 'dart:convert';

import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/user.prefs.service.dart';
import 'package:flutterping/util/ws/ws-client.dart';
import 'package:rxdart/rxdart.dart';

class GlobalAppService {
  static final GlobalAppService _appData = new GlobalAppService._internal();

  WsClient wsClient;

  Map<String, StreamSubscription> receivingMessagesSubs = new Map();
  PublishSubject<MessageDto> _receivingMessageStream = PublishSubject<MessageDto>();


  factory GlobalAppService() {
    return _appData;
  }

  GlobalAppService._internal() {
    init();
  }

  init() async {
    String userToken = await UserService.getToken();
    wsClient = new WsClient(userToken, onConnectedFunc: () {
      wsClient.subscribe(destination: '/user/messages/receive', callback: (frame) async {
        print('----messages receive');
        MessageDto newMessage = MessageDto.fromJson(json.decode(frame.body));
        _receivingMessageStream.add(newMessage);
      });
    });
  }

  StreamSubscription<MessageDto> listenToReceivingMessages(String key, Function callback) {
    if (receivingMessagesSubs.containsKey(key)) {
      receivingMessagesSubs[key].cancel();
      receivingMessagesSubs.remove(key);
      receivingMessagesSubs[key] = _receivingMessageStream.stream.listen(callback);
    } else {
      receivingMessagesSubs[key] = _receivingMessageStream.stream.listen(callback);
    }
  }
}

final globalAppService = GlobalAppService();


import 'dart:async';
import 'dart:convert';

import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/ws/publisher.dart';
import 'package:flutterping/service/ws/ws-client.dart';

class WsClientService {
  static final WsClientService _appData = new WsClientService._internal();

  factory WsClientService() {
    return _appData;
  }

  WsClientService._internal() {
    _initializeWsHandlers();
  }

  static WsClient _wsClient;

  static WsClient _wsFunc() => _wsClient;

  Publisher<int> userStatusPub = new Publisher();

  Publisher<MessageDto> receivingMessagesPub = new Publisher();
  Publisher<MessageDto> sendingMessagesPub = new Publisher(ws: _wsFunc);

  Publisher<MessageSeenDto> outgoingReceivedPub = new Publisher(ws: _wsFunc);
  Publisher<MessageSeenDto> outgoingSeenPub = new Publisher(ws: _wsFunc);

  Publisher<MessageDto> incomingSentPub = new Publisher();
  Publisher<int> incomingReceivedPub = new Publisher();
  Publisher<int> incomingSeenPub = new Publisher();

  _initializeWsHandlers() async {
    String userToken = await UserService.getToken();
    _wsClient = new WsClient(userToken, onConnectedFunc: () {
      _wsClient.subscribe(destination: '/user/messages/receive', callback: (frame) async {
        MessageDto newMessage = MessageDto.fromJson(json.decode(frame.body));
        receivingMessagesPub.subject.add(newMessage);
      });

      _wsClient.subscribe(destination: '/user/messages/seen', callback: (frame) async {
        int messageId = json.decode(frame.body);
        incomingSeenPub.subject.add(messageId);
      });

      _wsClient.subscribe(destination: '/user/messages/sent', callback: (frame) async {
        MessageDto message = MessageDto.fromJson(json.decode(frame.body));
        incomingSentPub.subject.add(message);
      });

      _wsClient.subscribe(destination: '/user/messages/received', callback: (frame) async {
        int messageId = json.decode(frame.body);
        incomingReceivedPub.subject.add(messageId);
      });

      _wsClient.subscribe(destination: '/users/status', callback: (frame) async {
        print('USERS STATUS CHANGE');
        print(1);
      });
    });
  }
}

final wsClientService = WsClientService();

sendMessage(MessageDto messageDto) {
  wsClientService.sendingMessagesPub.sendEvent(messageDto, '/messages/send');
}

sendSeenStatus(MessageSeenDto messageSeenDto) {
  wsClientService.outgoingSeenPub.sendEvent(messageSeenDto, '/messages/seen');
}

sendReceivedStatus(MessageSeenDto messageSeenDto) {
  wsClientService.outgoingReceivedPub.sendEvent(messageSeenDto, '/messages/received');
}

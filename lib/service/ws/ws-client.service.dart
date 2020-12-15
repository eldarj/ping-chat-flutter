
import 'dart:async';
import 'dart:convert';

import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/model/presence-event.model.dart';
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
  Publisher<List<MessageSeenDto>> outgoingSeenPub = new Publisher(ws: _wsFunc);

  Publisher<MessageDto> incomingSentPub = new Publisher();
  Publisher<int> incomingReceivedPub = new Publisher();
  Publisher<List<dynamic>> incomingSeenPub = new Publisher();

  Publisher<PresenceEvent> presencePub = new Publisher();

  _initializeWsHandlers() async {
    String userToken = await UserService.getToken();
    _wsClient = new WsClient(userToken, onConnectedFunc: () {
      _wsClient.subscribe(destination: '/user/messages/receive', callback: (frame) async {
        MessageDto newMessage = MessageDto.fromJson(json.decode(frame.body));
        receivingMessagesPub.subject.add(newMessage);
      });

      _wsClient.subscribe(destination: '/user/messages/seen', callback: (frame) async {
        List<dynamic> seenMessageIds = json.decode(frame.body);
        incomingSeenPub.subject.add(seenMessageIds);
      });

      _wsClient.subscribe(destination: '/user/messages/sent', callback: (frame) async {
        MessageDto message = MessageDto.fromJson(json.decode(frame.body));
        incomingSentPub.subject.add(message);
      });

      _wsClient.subscribe(destination: '/user/messages/received', callback: (frame) async {
        int messageId = json.decode(frame.body);
        incomingReceivedPub.subject.add(messageId);
      });
    });
  }

  Function subscribe(destination, callback) {
    return _wsClient.subscribe(destination: destination, callback: callback);
  }
}

final wsClientService = WsClientService();

sendMessage(MessageDto message) async {
  message.sender = await UserService.getUser();
  wsClientService.sendingMessagesPub.sendEvent(message, '/messages/send');
}

sendSeenStatus(List<MessageSeenDto> seenMessages) {
  wsClientService.outgoingSeenPub.sendEvent(seenMessages, '/messages/seen');
}

sendReceivedStatus(MessageSeenDto messageSeenDto) {
  wsClientService.outgoingReceivedPub.sendEvent(messageSeenDto, '/messages/received');
}
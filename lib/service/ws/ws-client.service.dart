
import 'dart:async';
import 'dart:convert';

import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/message-seen-dto.model.dart';
import 'package:flutterping/model/presence-event.model.dart';
import 'package:flutterping/model/typing-event.model.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/ws/ws-publisher.dart';
import 'package:flutterping/service/ws/ws-client.dart';

class WsClientService {
  static final WsClientService _appData = new WsClientService._internal();

  factory WsClientService() {
    return _appData;
  }

  WsClientService._internal() {
    _initializeWsHandlers();
  }

  static WsClient wsClient;

  static WsClient _wsFunc() => wsClient;

  WsPublisher<int> userStatusPub = new WsPublisher();

  WsPublisher<MessageDto> receivingMessagesPub = new WsPublisher();
  WsPublisher<MessageDto> editedMessagePub = new WsPublisher(ws: _wsFunc);
  WsPublisher<MessageDto> sendingMessagesPub = new WsPublisher(ws: _wsFunc);

  WsPublisher<MessageSeenDto> outgoingReceivedPub = new WsPublisher(ws: _wsFunc);
  WsPublisher<List<MessageSeenDto>> outgoingSeenPub = new WsPublisher(ws: _wsFunc);

  WsPublisher<MessageDto> incomingSentPub = new WsPublisher();
  WsPublisher<int> incomingReceivedPub = new WsPublisher();
  WsPublisher<List<dynamic>> incomingSeenPub = new WsPublisher();

  WsPublisher<PresenceEvent> presencePub = new WsPublisher();

  WsPublisher<MessageDto> messageDeletedPub = new WsPublisher(ws: _wsFunc);

  WsPublisher<TypingEvent> typingPub = new WsPublisher();

  _initializeWsHandlers() async {
    String userToken = await UserService.getToken();
    bool isActive = await UserService.getUserStatus();
    wsClient = new WsClient(userToken, isActive: isActive, onConnectedFunc: () {
      wsClient.subscribe(destination: '/user/messages/receive', callback: (frame) async {
        MessageDto newMessage = MessageDto.fromJson(json.decode(frame.body));
        receivingMessagesPub.subject.add(newMessage);
      });

      wsClient.subscribe(destination: '/user/messages/edited', callback: (frame) async {
        MessageDto editedMessage = MessageDto.fromJson(json.decode(frame.body));
        editedMessagePub.subject.add(editedMessage);
      });

      wsClient.subscribe(destination: '/user/messages/seen', callback: (frame) async {
        List<dynamic> seenMessageIds = json.decode(frame.body);
        incomingSeenPub.subject.add(seenMessageIds);
      });

      wsClient.subscribe(destination: '/user/messages/sent', callback: (frame) async {
        MessageDto message = MessageDto.fromJson(json.decode(frame.body));
        incomingSentPub.subject.add(message);
      });

      wsClient.subscribe(destination: '/user/messages/received', callback: (frame) async {
        int messageId = json.decode(frame.body);
        incomingReceivedPub.subject.add(messageId);
      });

      wsClient.subscribe(destination: '/user/messages/deleted', callback: (frame) async {
        MessageDto message = MessageDto.fromJson(json.decode(frame.body));
        messageDeletedPub.subject.add(message);
      });

      wsClient.subscribe(destination: '/user/users/typing', callback: (frame) async {
        TypingEvent typingEvent = TypingEvent.fromJson(json.decode(frame.body));
        typingPub.subject.add(typingEvent);
      });
    });
  }

  Function subscribe(destination, callback) {
    return wsClient.subscribe(destination: destination, callback: callback);
  }
}

WsClientService wsClientService;

instantiateWsClientService() {
  if (wsClientService == null) {
    wsClientService = WsClientService();
  }
}

sendSeenStatus(List<MessageSeenDto> seenMessages) async {
  await Future.delayed(Duration(seconds: 1));
  wsClientService.outgoingSeenPub.sendEvent(seenMessages, '/messages/seen');
}

sendReceivedStatus(MessageSeenDto messageSeenDto) {
  wsClientService.outgoingReceivedPub.sendEvent(messageSeenDto, '/messages/received');
}

sendPresenceEvent(PresenceEvent presenceEvent) {
  if (WsClientService.wsClient != null) {
    WsClientService.wsClient.send('/users/status', presenceEvent);
  }
}

sendTypingEvent(receiverPhoneNumber, status) {
  if (WsClientService.wsClient != null) {
    WsClientService.wsClient.send('/users/typing', new TypingEvent(
      receiverPhoneNumber: receiverPhoneNumber, status: status
    ));
  }
}

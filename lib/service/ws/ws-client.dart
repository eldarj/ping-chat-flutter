import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class WsClient {
  static const String _WS_SEND_PREFIX = '/ws';

  StompClient _stompClient;

  WsClient(userToken, {isActive = true, Function onConnectedFunc}) {
    if (userToken != null) {
      developer.log('WsClient - getClient - tryConnect with token: $userToken');
      _stompClient = StompClient(
          config: StompConfig(
              url: 'ws://192.168.1.25:8089/ws/connect',
              reconnectDelay: 5000,
              webSocketConnectHeaders: {
                'authorization': 'Bearer ${userToken}',
              },
              stompConnectHeaders: {
                'isActiveHeader': isActive.toString()
              },
              onStompError: (error) {
                developer.log('WsClient - getClient - onStompError: $error');
              },
              onWebSocketError: (error) {
                developer.log('WsClient - getClient - onWebSocketError: $error');
              },
              onDisconnect: (msg) {
                developer.log('WsClient - getClient - onDisconnect: $msg');
              },
              onConnect: (StompClient client, StompFrame connectFrame) {
                developer.log('WsClient - getClient - onConnected');
                if (onConnectedFunc != null) {
                  onConnectedFunc.call();
                }
              }
          )
      );

      _stompClient.activate();
    }
  }

  void send(String destination, dynamic body, {jsonEncode = true}) {
    if (_stompClient != null) {
      _stompClient.send(
        destination: _WS_SEND_PREFIX + destination,
        body: jsonEncode ? json.encode(body) : body,
      );
    }
  }

  Function({Map<String, String> unsubscribeHeaders}) subscribe({
    @required String destination,
    @required Function(StompFrame) callback,
    Map<String, String> headers
  }) {
    return _stompClient.subscribe(destination: destination, callback: callback, headers: headers);
  }

  destroy() {
    _stompClient.deactivate();
    _stompClient = null;
  }

  isConnected() {
    return _stompClient != null && _stompClient.connected;
  }
}

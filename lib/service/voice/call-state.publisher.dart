

import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:sip_ua/sip_ua.dart';

class CallEvent {
  Call call;
  CallState callState;

  CallEvent({this.call, this.callState});
}

class CallStatePublisher {
  static final CallStatePublisher _appData = new CallStatePublisher._internal();

  factory CallStatePublisher() {
    return _appData;
  }

  CallStatePublisher._internal();

  // Publishers
  Map<String, StreamSubscription> subs = new Map();
  PublishSubject<CallEvent> subject = PublishSubject<CallEvent>();

  addListener(String key, Function callback) {
    if (subs.containsKey(key)) {
      subs[key]?.cancel();
      subs.remove(key);
      subs[key] = subject.listen(callback);
    } else {
      subs[key] = subject.listen(callback);
    }
  }

  removeListener(String key) {
    subs[key]?.cancel();
    subs.remove(key);
  }
}

final callStatePublisher = new CallStatePublisher();

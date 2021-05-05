
import 'dart:async';

import 'package:rxdart/rxdart.dart';

class WsPublisher<T> {
  Function wsClientGetter;

  WsPublisher({ Function ws }) {
    this.wsClientGetter = ws;
  }

  Map<String, StreamSubscription> subs = new Map();
  PublishSubject<T> subject = PublishSubject<T>();

  sendEvent(T event, String destination) {
    subject.add(event);

    if (wsClientGetter != null && destination != null) {
      wsClientGetter().send(destination, event);
    }
  }

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

import 'dart:async';

import 'package:flutterping/model/message-download-progress.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:rxdart/rxdart.dart';

class UnreadMessagePublisher {
  static final UnreadMessagePublisher _appData = new UnreadMessagePublisher._internal();

  factory UnreadMessagePublisher() {
    return _appData;
  }

  UnreadMessagePublisher._internal();

  Map<String, StreamSubscription> subs = new Map();
  PublishSubject<int> subject = PublishSubject<int>();

  addListener(String key, Function callback) {
    if (subs.containsKey(key)) {
      subs[key].cancel();
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

final unreadMessagePublisher = UnreadMessagePublisher();


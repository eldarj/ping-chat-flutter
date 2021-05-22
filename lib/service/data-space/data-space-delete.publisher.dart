import 'dart:async';

import 'package:flutterping/model/message-download-progress.model.dart';
import 'package:rxdart/rxdart.dart';

class DataSpaceDeletePublisher {
  static final DataSpaceDeletePublisher _appData = new DataSpaceDeletePublisher._internal();

  factory DataSpaceDeletePublisher() {
    return _appData;
  }

  DataSpaceDeletePublisher._internal();

  Map<String, StreamSubscription> subs = {};

  PublishSubject<int> subject = PublishSubject<int>();

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

final dataSpaceDeletePublisher = DataSpaceDeletePublisher();


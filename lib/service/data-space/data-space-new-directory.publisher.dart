import 'dart:async';

import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:rxdart/rxdart.dart';

class DataSpaceNewDirectoryPublisher {
  static final DataSpaceNewDirectoryPublisher _appData = new DataSpaceNewDirectoryPublisher._internal();

  factory DataSpaceNewDirectoryPublisher() {
    return _appData;
  }

  DataSpaceNewDirectoryPublisher._internal();

  Map<String, StreamSubscription> subs = new Map();
  PublishSubject<DSNodeDto> subject = PublishSubject<DSNodeDto>();

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

final dataSpaceNewDirectoryPublisher = DataSpaceNewDirectoryPublisher();


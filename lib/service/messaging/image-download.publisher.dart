import 'dart:async';

import 'package:flutterping/model/message-download-progress.model.dart';
import 'package:rxdart/rxdart.dart';

class ImageDownloadPublisher {
  static final ImageDownloadPublisher _appData = new ImageDownloadPublisher._internal();

  factory ImageDownloadPublisher() {
    return _appData;
  }

  ImageDownloadPublisher._internal();

  Map<String, StreamSubscription> subs = new Map();
  PublishSubject<MessageDownloadProgress> subject = PublishSubject<MessageDownloadProgress>();

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

final imageDownloadPublisher = ImageDownloadPublisher();


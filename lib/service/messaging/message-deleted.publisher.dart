import 'dart:async';

import 'package:flutterping/model/message-dto.model.dart';
import 'package:rxdart/rxdart.dart';

class MessageDeletedPublisher {
  static final MessageDeletedPublisher _instance = new MessageDeletedPublisher._internal();

  factory MessageDeletedPublisher() {
    return _instance;
  }

  MessageDeletedPublisher._internal();

  Map<String, StreamSubscription> _subs = {};

  PublishSubject<MessageDto> _subject = PublishSubject<MessageDto>();

  onMessageDeleted(String key, Function callback) {
    if (_subs.containsKey(key)) {
      _subs[key]?.cancel();
      _subs.remove(key);
      _subs[key] = _subject.listen(callback);
    } else {
      _subs[key] = _subject.listen(callback);
    }
  }

  emitMessageDeleted(MessageDto message) {
    _subject.add(message);
  }

  removeListener(String key) {
    _subs[key]?.cancel();
    _subs.remove(key);
  }
}

final messageDeletedPublisher = MessageDeletedPublisher._internal();


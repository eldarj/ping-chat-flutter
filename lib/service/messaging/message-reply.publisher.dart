import 'dart:async';

import 'package:flutterping/model/message-dto.model.dart';
import 'package:rxdart/rxdart.dart';

class MessageReplyPublisher {
  static final MessageReplyPublisher _instance = new MessageReplyPublisher._internal();

  Map<String, StreamSubscription> _subs = {};

  PublishSubject<MessageDto> _subject = PublishSubject<MessageDto>();

  factory MessageReplyPublisher() {
    return _instance;
  }

  MessageReplyPublisher._internal();

  onReplyEvent(String key, Function callback) {
    if (_subs.containsKey(key)) {
      _subs[key]?.cancel();
      _subs.remove(key);
      _subs[key] = _subject.listen(callback);
    } else {
      _subs[key] = _subject.listen(callback);
    }
  }

  emitReplyEvent(MessageDto message) {
    _subject.add(message);
  }

  removeListener(String key) {
    _subs[key]?.cancel();
    _subs.remove(key);
  }
}

final messageReplyPublisher = MessageReplyPublisher._internal();


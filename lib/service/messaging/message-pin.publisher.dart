import 'dart:async';

import 'package:rxdart/rxdart.dart';

class PinEvent {
  int messageId;
  bool pinned;

  PinEvent(this.messageId, this.pinned);
}

class MessagePinPublisher {
  static final MessagePinPublisher _instance = new MessagePinPublisher._internal();

  Map<String, StreamSubscription> _subs = {};


  PublishSubject<PinEvent> _subject = PublishSubject<PinEvent>();

  factory MessagePinPublisher() {
    return _instance;
  }

  MessagePinPublisher._internal();

  onPinUpdate(String key, Function callback) {
    if (_subs.containsKey(key)) {
      _subs[key]?.cancel();
      _subs.remove(key);
      _subs[key] = _subject.listen(callback);
    } else {
      _subs[key] = _subject.listen(callback);
    }
  }

  emitPinUpdate(int messageId, bool pinned) {
    _subject.add(new PinEvent(messageId, pinned));
  }

  removeListener(String key) {
    _subs[key]?.cancel();
    _subs.remove(key);
  }
}

final messagePinPublisher = MessagePinPublisher._internal();


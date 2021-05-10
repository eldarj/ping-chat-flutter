import 'dart:async';

import 'package:flutterping/model/message-dto.model.dart';
import 'package:rxdart/rxdart.dart';

class EditEvent {
  MessageDto message;
  String text;

  EditEvent(this.message, this.text);
}

class MessageEditPublisher {
  static final MessageEditPublisher _instance = new MessageEditPublisher._internal();

  Map<String, StreamSubscription> _subs = {};


  PublishSubject<EditEvent> _subject = PublishSubject<EditEvent>();

  factory MessageEditPublisher() {
    return _instance;
  }

  MessageEditPublisher._internal();

  onEditEvent(String key, Function callback) {
    if (_subs.containsKey(key)) {
      _subs[key]?.cancel();
      _subs.remove(key);
      _subs[key] = _subject.listen(callback);
    } else {
      _subs[key] = _subject.listen(callback);
    }
  }

  emitEditEvent(MessageDto message, String text) {
    _subject.add(new EditEvent(message, text));
  }

  removeListener(String key) {
    _subs[key]?.cancel();
    _subs.remove(key);
  }
}

final messageEditPublisher = MessageEditPublisher._internal();


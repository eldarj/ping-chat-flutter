import 'dart:async';

import 'package:rxdart/rxdart.dart';

class ProfilePublisher {
  static final ProfilePublisher _instance = new ProfilePublisher._internal();

  Map<String, StreamSubscription> _subs = {};


  PublishSubject<String> _profileImageSubject = PublishSubject<String>();

  factory ProfilePublisher() {
    return _instance;
  }

  ProfilePublisher._internal();

  onProfileImageUpdate(String key, Function callback) {
    if (_subs.containsKey(key)) {
      _subs[key].cancel();
      _subs.remove(key);
      _subs[key] = _profileImageSubject.listen(callback);
    } else {
      _subs[key] = _profileImageSubject.listen(callback);
    }
  }

  emitProfileImageUpdate(String profileImage) {
    _profileImageSubject.add(profileImage);
  }

  removeListener(String key) {
      _subs[key]?.cancel();
      _subs.remove(key);
  }
}

final profilePublisher = ProfilePublisher._internal();


import 'dart:async';

import 'package:rxdart/rxdart.dart';

enum EventType {
  FAVOURITES, CONTACT_NAME, BACKGROUND_IMAGE
}

class ContactEvent {
  int contactBindingId;
  int contactUserId;
  dynamic value;

  ContactEvent(this.contactBindingId, this.value, { this.contactUserId });
}

class ContactPublisher {
  static final ContactPublisher _instance = new ContactPublisher._internal();

  Map<EventType, Map<String, StreamSubscription>> _subs = {
    EventType.FAVOURITES: {},
    EventType.CONTACT_NAME: {},
    EventType.BACKGROUND_IMAGE: {},
  };

  PublishSubject<ContactEvent> _contactNameSubject = PublishSubject<ContactEvent>();
  PublishSubject<ContactEvent> _backgroundSubject = PublishSubject<ContactEvent>();
  PublishSubject<ContactEvent> _favouriteSubject = PublishSubject<ContactEvent>();

  factory ContactPublisher() {
    return _instance;
  }

  ContactPublisher._internal();

  // Favourites update
  onFavouritesUpdate(String key, Function callback) {
    var favouriteSubs = _subs[EventType.FAVOURITES];
    _addListener(favouriteSubs, _favouriteSubject, key, callback);
  }

  emitFavouritesUpdate(int contactBindingId, bool status) {
    _favouriteSubject.add(ContactEvent(contactBindingId, status));
  }

  // Contact name update
  onNameUpdate(String key, Function callback) {
    var nameSubs = _subs[EventType.CONTACT_NAME];
    _addListener(nameSubs, _contactNameSubject, key, callback);
  }

  emitNameUpdate(int contactBindingId, int contactUserId, String name) {
    _contactNameSubject.add(ContactEvent(contactBindingId, name, contactUserId: contactUserId));
  }

  // Background update
  onBackgroundUpdate(String key, Function callback) {
    var backgroundImageSubs = _subs[EventType.BACKGROUND_IMAGE];
    _addListener(backgroundImageSubs, _backgroundSubject, key, callback);
  }

  emitBackgroundUpdate(int contactBindingId, String backgroundImagePath) {
    _backgroundSubject.add(ContactEvent(contactBindingId, backgroundImagePath));
  }

  removeListener(String key) {
    _subs.forEach((key, value) {
      Map<String, StreamSubscription> subsByType = _subs[key];
      subsByType[key]?.cancel();
      subsByType.remove(key);
    });
  }

  _addListener(Map<String, StreamSubscription> subs, PublishSubject<ContactEvent> subject, String key, Function callback) {
    if (subs.containsKey(key)) {
      subs[key].cancel();
      subs.remove(key);
      subs[key] = subject.listen(callback);
    } else {
      subs[key] = subject.listen(callback);
    }
  }
}

final contactPublisher = ContactPublisher._internal();


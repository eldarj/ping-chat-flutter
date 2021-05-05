import 'dart:async';

import 'package:rxdart/rxdart.dart';

enum EventType {
  FAVOURITES, CONTACT_NAME, BACKGROUND_IMAGE, CONTACT_DELETE, MESSAGES_DELETE
}

class ContactEvent {
  int contactBindingId;
  int contactUserId;
  dynamic value;

  ContactEvent(this.contactBindingId, { this.value, this.contactUserId });
}

class ContactPublisher {
  static final ContactPublisher _instance = new ContactPublisher._internal();

  Map<EventType, Map<String, StreamSubscription>> _subs = {
    EventType.FAVOURITES: {},
    EventType.CONTACT_NAME: {},
    EventType.BACKGROUND_IMAGE: {},
    EventType.CONTACT_DELETE: {},
    EventType.MESSAGES_DELETE: {},
  };

  PublishSubject<ContactEvent> _contactNameSubject = PublishSubject<ContactEvent>();
  PublishSubject<ContactEvent> _backgroundSubject = PublishSubject<ContactEvent>();
  PublishSubject<ContactEvent> _favouriteSubject = PublishSubject<ContactEvent>();
  PublishSubject<ContactEvent> _deleteContactSubject = PublishSubject<ContactEvent>();
  PublishSubject<ContactEvent> _deleteMessagesSubject = PublishSubject<ContactEvent>();

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
    _favouriteSubject.add(ContactEvent(contactBindingId, value: status));
  }

  // Contact name update
  onNameUpdate(String key, Function callback) {
    var nameSubs = _subs[EventType.CONTACT_NAME];
    _addListener(nameSubs, _contactNameSubject, key, callback);
  }

  emitNameUpdate(int contactBindingId, int contactUserId, String name) {
    _contactNameSubject.add(ContactEvent(contactBindingId, value: name, contactUserId: contactUserId));
  }

  // Background update
  onBackgroundUpdate(String key, Function callback) {
    var backgroundImageSubs = _subs[EventType.BACKGROUND_IMAGE];
    _addListener(backgroundImageSubs, _backgroundSubject, key, callback);
  }

  emitBackgroundUpdate(int contactBindingId, String backgroundImagePath) {
    _backgroundSubject.add(ContactEvent(contactBindingId, value: backgroundImagePath));
  }

  // Contact delete
  onContactDelete(String key, Function callback) {
    var subs = _subs[EventType.CONTACT_DELETE];
    _addListener(subs, _deleteContactSubject, key, callback);
  }

  emitContactDelete(int contactBindingId) {
    _deleteContactSubject.add(ContactEvent(contactBindingId));
  }

  // All messages delete
  onAllMessagesDelete(String key, Function callback) {
    var subs = _subs[EventType.MESSAGES_DELETE];
    _addListener(subs, _deleteMessagesSubject, key, callback);
  }

  emitAllMessagesDelete(int contactBindingId) {
    _deleteMessagesSubject.add(ContactEvent(contactBindingId));
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
      subs[key]?.cancel();
      subs.remove(key);
      subs[key] = subject.listen(callback);
    } else {
      subs[key] = subject.listen(callback);
    }
  }
}

final contactPublisher = ContactPublisher._internal();


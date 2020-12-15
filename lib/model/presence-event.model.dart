class PresenceEvent {

  String userPhoneNumber;
  bool status;
  int eventTimestamp;

  PresenceEvent({this.userPhoneNumber, this.status, this.eventTimestamp});

  factory PresenceEvent.fromJson(Map<String, dynamic> parsedJson) {
    return PresenceEvent()
      ..userPhoneNumber = parsedJson['userPhoneNumber'] as String
      ..status = parsedJson['status'] as bool
      ..eventTimestamp = parsedJson['eventTimestamp'] as int;
  }

  Map<String, dynamic> toJson() => {
    'userPhoneNumber': userPhoneNumber,
    'status': status,
    'eventTimestamp': eventTimestamp,
  };
}

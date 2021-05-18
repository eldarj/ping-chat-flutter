class TypingEvent {

  String receiverPhoneNumber;
  String senderPhoneNumber;
  bool status;

  TypingEvent({this.receiverPhoneNumber, this.senderPhoneNumber, this.status});

  factory TypingEvent.fromJson(Map<String, dynamic> parsedJson) {
    return TypingEvent()
      ..receiverPhoneNumber = parsedJson['receiverPhoneNumber'] as String
      ..senderPhoneNumber = parsedJson['senderPhoneNumber'] as String
      ..status = parsedJson['status'] as bool;
  }

  Map<String, dynamic> toJson() => {
    'receiverPhoneNumber': receiverPhoneNumber,
    'senderPhoneNumber': senderPhoneNumber,
    'status': status,
  };
}

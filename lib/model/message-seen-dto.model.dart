class MessageSeenDto {
  int id;

  String senderPhoneNumber;

  MessageSeenDto({this.id, this.senderPhoneNumber});

  factory MessageSeenDto.fromJson(Map<String, dynamic> parsedJson) {
    return MessageSeenDto()
      ..id = parsedJson['id'] as int
      ..senderPhoneNumber = parsedJson['senderPhoneNumber'] as String;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderPhoneNumber': senderPhoneNumber,
  };
}

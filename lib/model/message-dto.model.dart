import 'package:flutterping/model/client-dto.model.dart';

class MessageDto {
  int id;

  String text;

  ClientDto sender;
  ClientDto receiver;

  bool received;
  bool seen;

  String senderContactName;
  String receiverContactName;

  String sentTimestamp;

  MessageDto({this.id, this.text, this.sender, this.receiver, this.received, this.seen,
    this.senderContactName, this.receiverContactName, this.sentTimestamp});

  factory MessageDto.fromJson(Map<String, dynamic> parsedJson) {
    return MessageDto()
      ..id = parsedJson['id'] as int
      ..text = parsedJson['text'] as String
      ..sender = parsedJson['sender'] == null
          ? null
          : ClientDto.fromJson(parsedJson['sender'] as Map<String, dynamic>)
      ..receiver = parsedJson['receiver'] == null
          ? null
          : ClientDto.fromJson(parsedJson['receiver'] as Map<String, dynamic>)
      ..received = parsedJson['received'] as bool
      ..seen = parsedJson['seen'] as bool
      ..senderContactName = parsedJson['senderContactName'] as String
      ..receiverContactName = parsedJson['receiverContactName'] as String
      ..sentTimestamp = parsedJson['sentTimestamp'] as String;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'sender': sender,
    'receiver': receiver,
    'received': received,
    'seen': seen,
    'senderContactName': senderContactName,
    'receiverContactName': receiverContactName,
    'sentTimestamp': sentTimestamp,
  };
}

import 'package:flutterping/model/client-dto.model.dart';

class MessageDto {
  int id;

  String text;

  ClientDto sender;
  ClientDto receiver;

  bool sent;
  bool received;
  bool seen;

  bool displayCheckMark;

  String senderContactName;
  String receiverContactName;

  bool senderOnline;
  bool receiverOnline;

  int senderLastOnlineTimestamp;
  int receiverLastOnlineTimestamp;

  int sentTimestamp;

  int contactBindingId;

  bool isChained;

  MessageDto({this.id, this.text, this.sender, this.receiver, this.sent, this.received, this.seen,
    this.displayCheckMark, this.senderContactName, this.receiverContactName, this.sentTimestamp,
    this.contactBindingId, this.isChained});

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
      ..sent = parsedJson['sent'] as bool
      ..received = parsedJson['received'] as bool
      ..seen = parsedJson['seen'] as bool
      ..displayCheckMark = parsedJson['displayCheckMark'] == null ? false : parsedJson['displayCheckMark'] as bool
      ..senderContactName = parsedJson['senderContactName'] as String
      ..receiverContactName = parsedJson['receiverContactName'] as String
      ..senderOnline = parsedJson['senderOnline'] as bool
      ..receiverOnline = parsedJson['receiverOnline'] as bool
      ..senderLastOnlineTimestamp = parsedJson['senderLastOnlineTimestamp'] as int
      ..receiverLastOnlineTimestamp = parsedJson['receiverLastOnlineTimestamp'] as int
      ..sentTimestamp = parsedJson['sentTimestamp'] as int
      ..contactBindingId = parsedJson['contactBindingId'] as int
      ..isChained = parsedJson['isChained'] == null ? false : parsedJson['isChained'] as bool;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'sender': sender,
    'receiver': receiver,
    'sent': sent,
    'received': received,
    'seen': seen,
    'displayCheckMark': displayCheckMark,
    'senderContactName': senderContactName,
    'receiverContactName': receiverContactName,
    'senderOnline': senderOnline,
    'receiverOnline': receiverOnline,
    'senderLastOnlineTimestamp': senderLastOnlineTimestamp,
    'receiverLastOnlineTimestamp': receiverLastOnlineTimestamp,
    'sentTimestamp': sentTimestamp,
    'contactBindingId': contactBindingId,
    'isChained': isChained,
  };
}

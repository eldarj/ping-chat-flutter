import 'package:flutterping/model/client-dto.model.dart';

class ContactDto {
  int id;

  ClientDto contactUser;
  String contactPhoneNumber;
  String contactName;
  bool favorite;
  bool contactUserExists;

  int joinedTimestamp;

  int contactBindingId;

  bool displayLinearLoading = false;

  ContactDto({this.id, this.contactPhoneNumber, this.contactUser, this.contactName,
    this.favorite, this.contactUserExists, this.joinedTimestamp, this.contactBindingId});

  factory ContactDto.fromJson(Map<String, dynamic> parsedJson) {
    return ContactDto()
      ..id = parsedJson['id'] as int
      ..contactPhoneNumber = parsedJson['contactPhoneNumber'] as String
      ..contactUser = parsedJson['contactUser'] == null
          ? null
          : ClientDto.fromJson(parsedJson['contactUser'] as Map<String, dynamic>)
      ..contactName = parsedJson['contactName'] as String
      ..favorite = parsedJson['favorite'] as bool
      ..contactUserExists = parsedJson['contactUserExists'] as bool
      ..joinedTimestamp = parsedJson['joinedTimestamp'] as int
      ..contactBindingId = parsedJson['contactBindingId'] as int;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactPhoneNumber': contactPhoneNumber,
    'contactUser': contactUser,
    'contactName': contactName,
    'favorite': favorite,
    'contactUserExists': contactUserExists,
    'joinedTimestamp': joinedTimestamp,
    'contactBindingId': contactBindingId,
  };
}

import 'package:flutterping/model/client-dto.model.dart';

class ContactDto {
  int id;

  ClientDto contactUser;
  String contactPhoneNumber;
  String contactName;
  bool isFavorite;

  int joinedTimestamp;

  ContactDto({this.id, this.contactPhoneNumber, this.contactUser, this.contactName, this.isFavorite, this.joinedTimestamp});

  factory ContactDto.fromJson(Map<String, dynamic> parsedJson) {
    return ContactDto()
      ..id = parsedJson['id'] as int
      ..contactPhoneNumber = parsedJson['contactPhoneNumber'] as String
      ..contactUser = parsedJson['contactUser'] == null
          ? null
          : ClientDto.fromJson(parsedJson['contactUser'] as Map<String, dynamic>)
      ..contactName = parsedJson['contactName'] as String
      ..isFavorite = parsedJson['isFavorite'] as bool
      ..joinedTimestamp = parsedJson['joinedTimestamp'] as int;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactPhoneNumber': contactPhoneNumber,
    'contactUser': contactUser,
    'contactName': contactName,
    'isFavorite': isFavorite,
    'joinedTimestamp': joinedTimestamp,
  };
}

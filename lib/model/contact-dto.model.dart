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

  String backgroundImagePath;

  bool deleted;

  ContactDto({this.id, this.contactPhoneNumber, this.contactUser, this.contactName, this.deleted,
    this.favorite, this.contactUserExists, this.joinedTimestamp, this.contactBindingId});

  factory ContactDto.fromJson(Map<String, dynamic> parsedJson) {
    return ContactDto()
      ..id = parsedJson['id'] as int
      ..contactPhoneNumber = parsedJson['contactPhoneNumber'] as String
      ..contactUser = parsedJson['contactUser'] == null
          ? null
          : ClientDto.fromJson(parsedJson['contactUser'] as Map<String, dynamic>)
      ..contactName = parsedJson['contactName'] as String
      ..backgroundImagePath = parsedJson['backgroundImagePath'] as String
      ..favorite = parsedJson['favorite'] as bool
      ..deleted = parsedJson['deleted'] as bool
      ..contactUserExists = parsedJson['contactUserExists'] as bool
      ..joinedTimestamp = parsedJson['joinedTimestamp'] as int
      ..contactBindingId = parsedJson['contactBindingId'] as int;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactPhoneNumber': contactPhoneNumber,
    'contactUser': contactUser,
    'contactName': contactName,
    'backgroundImagePath': backgroundImagePath,
    'favorite': favorite,
    'deleted': deleted,
    'contactUserExists': contactUserExists,
    'joinedTimestamp': joinedTimestamp,
    'contactBindingId': contactBindingId,
  };
}

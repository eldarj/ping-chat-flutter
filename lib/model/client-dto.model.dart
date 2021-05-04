import 'country-code-dto.model.dart';

class ClientDto {
  int id;

  String phoneNumber;
  CountryCodeDto countryCode;
  String firstName;
  String lastName;
  bool displayMyFullName;

  int joinedTimestamp;

  String profileImagePath;

  bool isActive;

  int sentNodeId;

  int receivedNodeId;

  String backgroundImagePath;

  ClientDto();

  factory ClientDto.fromJson(Map<String, dynamic> json) {
    return ClientDto()
      ..id = json['id'] as int
      ..phoneNumber = json['phoneNumber'] as String
      ..countryCode = json['countryCode'] == null
          ? null
          : CountryCodeDto.fromJson(json['countryCode'] as Map<String, dynamic>)
      ..firstName = json['firstName'] as String
      ..lastName = json['lastName'] as String
      ..displayMyFullName = json['displayMyFullName'] as bool
      ..joinedTimestamp = json['joinedTimestamp'] as int
      ..sentNodeId = json['sentNodeId'] as int
      ..receivedNodeId = json['receivedNodeId'] as int
      ..isActive = json['isActive'] as bool
      ..backgroundImagePath = json['backgroundImagePath'] as String
      ..profileImagePath = json['profileImagePath'] as String;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phoneNumber': phoneNumber,
    'countryCode': countryCode,
    'firstName': firstName,
    'lastName': lastName,
    'displayMyFullName': displayMyFullName,
    'joinedTimestamp': joinedTimestamp,
    'isActive': isActive,
    'sentNodeId': sentNodeId,
    'receivedNodeId': receivedNodeId,
    'backgroundImagePath': backgroundImagePath,
    'profileImagePath': profileImagePath,
  };

  get fullPhoneNumber => countryCode.dialCode + phoneNumber;
}

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
      ..isActive = json['isActive'] as bool
      ..profileImagePath = json['profileImagePath'] as String;
  }

  Map<String, dynamic> toJson(ClientDto instance) {
    return <String, dynamic>{
      'id': instance.id,
      'phoneNumber': instance.phoneNumber,
      'countryCode': instance.countryCode,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'displayMyFullName': instance.displayMyFullName,
      'joinedTimestamp': instance.joinedTimestamp,
      'isActive': instance.isActive,
      'profileImagePath': instance.profileImagePath,
    };
  }

  get fullPhoneNumber => countryCode.dialCode + phoneNumber;
}

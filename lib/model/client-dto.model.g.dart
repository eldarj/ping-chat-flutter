// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client-dto.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientDto _$ClientDtoFromJson(Map<String, dynamic> json) {
  return ClientDto()
    ..id = json['id'] as int
    ..phoneNumber = json['phoneNumber'] as String
    ..countryCode = json['countryCode'] == null
        ? null
        : CountryCodeDto.fromJson(json['countryCode'] as Map<String, dynamic>)
    ..firstName = json['firstName'] as String
    ..lastName = json['lastName'] as String
    ..joinedTimestamp = json['joinedTimestamp'] as int
    ..isActive = json['isActive'] as bool
    ..profileImagePath = json['profileImagePath'] as String;
}

Map<String, dynamic> _$ClientDtoToJson(ClientDto instance) => <String, dynamic>{
      'id': instance.id,
      'phoneNumber': instance.phoneNumber,
      'countryCode': instance.countryCode,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'joinedTimestamp': instance.joinedTimestamp,
      'isActive': instance.isActive,
      'profileImagePath': instance.profileImagePath,
    };

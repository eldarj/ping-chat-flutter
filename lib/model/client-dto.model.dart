import 'package:json_annotation/json_annotation.dart';

import 'country-code-dto.model.dart';

part 'client-dto.model.g.dart';
@JsonSerializable()
class ClientDto {
  int id;

  String phoneNumber;
  CountryCodeDto countryCode;
  String firstName;
  String lastName;

  int joinedTimestamp;

  String profileImagePath;

  bool isActive;

  ClientDto();

  factory ClientDto.fromJson(Map<String, dynamic> json) => _$ClientDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ClientDtoToJson(this);
}

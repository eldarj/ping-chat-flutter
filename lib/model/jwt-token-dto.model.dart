import 'client-dto.model.dart';

class JwtTokenDto {
  int id;

  ClientDto user;
  String token;

  String generatedTimestamp;

  JwtTokenDto({this.id, this.token, this.user, this.generatedTimestamp});

  factory JwtTokenDto.fromJson(Map<String, dynamic> parsedJson) {
    return JwtTokenDto(
        id: parsedJson['id'],
        token: parsedJson['token'],
        user: ClientDto.fromJson(parsedJson['user']),
        generatedTimestamp: parsedJson['generatedTimestamp']
    );
  }
}

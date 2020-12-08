class CountryCodeDto {
  int id;

  String countryName;
  String dialCode;

  CountryCodeDto({this.id, this.countryName, this.dialCode});

  factory CountryCodeDto.fromJson(Map<String, dynamic> parsedJson) {
    return parsedJson == null ? parsedJson : CountryCodeDto(
      id: parsedJson['id'],
      countryName: parsedJson['countryName'],
      dialCode: parsedJson['dialCode'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'countryName': countryName,
    'dialCode': dialCode,
  };
}

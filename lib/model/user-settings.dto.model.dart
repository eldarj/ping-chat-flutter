class UserSettingsDto {
  int id;

  String chatBubbleColorHex;

  bool darkMode;

  bool vibrate;

  bool receiveNotifications;

  UserSettingsDto();

  factory UserSettingsDto.fromJson(Map<String, dynamic> json) {
    return UserSettingsDto()
      ..id = json['id'] as int
      ..chatBubbleColorHex = json['chatBubbleColorHex'] as String
      ..darkMode = json['darkMode'] as bool
      ..vibrate = json['vibrate'] as bool
      ..receiveNotifications = json['receiveNotifications'] as bool
    ;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatBubbleColorHex': chatBubbleColorHex,
    'darkMode': darkMode,
    'vibrate': vibrate,
    'receiveNotifications': receiveNotifications,
  };
}

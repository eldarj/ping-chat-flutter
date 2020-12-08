import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterping/model/client-dto.model.dart';

String USER_SHARED_PREFS_KEY = 'USER_DTO_AS_JSON';
String USER_TOKEN_SHARED_PREFS_KEY = 'USER_DTO_TOKEN_AS_STRING';

class UserService {
  static var userVar;

  static getUser() async {
    if (userVar != null) {
      return userVar;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userJson = prefs.getString(USER_SHARED_PREFS_KEY);

    if (userJson == null) {
      return null;
    }

    var jsonDecodedUserDto = json.decode(userJson);

    var userDto = null;
    if (jsonDecodedUserDto != null) {
      userDto = ClientDto.fromJson(jsonDecodedUserDto);
    }

    return userDto;
  }

  static getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(USER_TOKEN_SHARED_PREFS_KEY);
  }

  static setUser(dynamic userDto) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var isActive = await getUserStatus();
    userDto.isActive = isActive;

    var userJson = json.encode(userDto);
    await prefs.setString(USER_SHARED_PREFS_KEY, userJson);

    userVar = userDto;
  }

  static setUserAndToken(String token, dynamic userDto) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(USER_TOKEN_SHARED_PREFS_KEY, token.replaceAll("Bearer ", ""));
    var userJson = json.encode(userDto);

    await prefs.setString(USER_SHARED_PREFS_KEY, userJson);

    userVar = userDto;
  }

  static void setUserStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userJson = prefs.getString(USER_SHARED_PREFS_KEY);
    var userDto = json.decode(userJson);
    userDto['isActive'] = status;

    await prefs.setString(USER_SHARED_PREFS_KEY, json.encode(userDto));

    if (userVar != null) {
      userVar.isActive = status;
    }
  }

  static Future<bool> getUserStatus() async {
    if (userVar != null && userVar.isActive != null) {
      return userVar.isActive;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userJson = prefs.getString(USER_SHARED_PREFS_KEY);

    if (userJson != null) {
      var userDto = ClientDto.fromJson(json.decode(userJson));
      userVar = userDto;

      return userDto.isActive != null && userDto.isActive;
    }

    return false;
  }

  static void setUserProfileImagePath(String profileImagePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userDto = json.decode(prefs.getString(USER_SHARED_PREFS_KEY));
    userDto['profileImagePath'] = profileImagePath;

    await prefs.setString(USER_SHARED_PREFS_KEY, json.encode(userDto));

    userVar.profileImagePath = profileImagePath;
  }

  static remove() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(USER_SHARED_PREFS_KEY);
    await prefs.remove(USER_TOKEN_SHARED_PREFS_KEY);
    userVar = null;
  }
}

import 'dart:convert';

import 'package:flutterping/model/message-dto.model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String CHATS_PREFS_KEY = 'CHATS_PREFS_KEY';

class ChatPrefsService {
  static List<MessageDto> chats = List();

  static containsChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(CHATS_PREFS_KEY);
  }

  static setChats(_chats) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var chatsJson = json.encode(_chats);
    await prefs.setString(CHATS_PREFS_KEY, chatsJson);

    chats = _chats;
  }

  static Future<List<MessageDto>> getChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var chatsJson = prefs.getString(CHATS_PREFS_KEY);
    var decodedChats = json.decode(chatsJson);

    if (decodedChats != null) {
      var list = decodedChats.map<MessageDto>((element) {
        return MessageDto.fromJson(element);
      }).toList();

      String pox = 'asd';

      chats = list;
    }

    return chats;
  }
}

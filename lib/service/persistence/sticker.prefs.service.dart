import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

String RECENT_STICKERS_SHARED_PREFS_KEY = 'RECENT_STICKERS_SHARED_PREFS_KEY';

class StickerService {
  Future<List> loadRecent() async {
    List stickerList = [];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String stickerJson = prefs.getString(RECENT_STICKERS_SHARED_PREFS_KEY);

    if (stickerJson != null) {
      stickerList = json.decode(stickerJson);
    }

    return stickerList;
  }

  Future<List> addRecent(stickerName) async {
    List stickerList;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String stickerJson = prefs.getString(RECENT_STICKERS_SHARED_PREFS_KEY);

    if (stickerJson == null) {
      stickerList = [stickerName];
    } else {
      stickerList = json.decode(stickerJson);
      if (!stickerList.contains(stickerName)) {
        stickerList.insert(0, stickerName);

        if (stickerList.length > 10) {
          stickerList.removeLast();
        }
      }
    }

    stickerJson = json.encode(stickerList);
    await prefs.setString(RECENT_STICKERS_SHARED_PREFS_KEY, stickerJson);

    return stickerList;
  }
}

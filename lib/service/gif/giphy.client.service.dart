
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:http/http.dart' as http;

class GiphyClientService {
  static final GiphyClientService _appData = new GiphyClientService._internal();

  String _giphyEndpoint;

  factory GiphyClientService() {
    return _appData;
  }

  GiphyClientService._internal() {
    _giphyEndpoint = "https://api.giphy.com/v1/gifs/search"
        "?api_key=846OBurQopjXvDr2eCxHwFntcrkDU3Wk"
        "&limit=10"
        "&q=";
  }

  Future<List<String>> getGifs(String query) async {
    List<String> gifUrls = [];

    try {
      var response = await http.get(Uri.encodeFull(_giphyEndpoint + query))
          .timeout(Duration(seconds: 10));

      Map<String, dynamic> jsonResponse = response.decode();

      List data = jsonResponse['data'];

      data.forEach((element) {
        try {
          gifUrls.add(element['images']['fixed_width_small']['url']);
        } catch (ignored) {
        }
      });

    } catch (ignored) {
    }

    return gifUrls;
  }
}

final giphyClientService = GiphyClientService();

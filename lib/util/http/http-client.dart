import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutterping/service/user.prefs.service.dart';

class HttpClient {
  static String _API_BASE_URL = 'http://192.168.1.4:8089';

  static Future<http.Response> post(url, {body = const {}, headers = const {}, bool encode = true}) async {
    var userToken = await UserService.getToken();

    var response = await http.post(
        Uri.encodeFull(_API_BASE_URL + url),
        headers: {'content-type': 'application/json', 'authorization': 'Bearer $userToken',...headers},
        body: encode ? json.encode(body) : body
    ).timeout(Duration(seconds: 10));

    return response;
  }

  static Future<http.Response> get(url) async {
    var userToken = await UserService.getToken();

    var response = await http.get(
        Uri.encodeFull(_API_BASE_URL + url),
        headers: {'content-type': 'application/json', 'authorization': 'Bearer $userToken'}
    ).timeout(Duration(seconds: 10));

    return response;
  }

  static Future<http.StreamedResponse> postMultipartFile(String url, String filename, File file,
      {String multipartFieldName: 'file'}) async
  {
    var userToken = await UserService.getToken();
    var headers = { 'authorization': 'Bearer $userToken' };

    var request = http.MultipartRequest('POST', Uri.parse(_API_BASE_URL + url));
    request.files.add(
        http.MultipartFile(
            multipartFieldName,
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: filename
        )
    );
    request.headers.addAll(headers);
    return request.send();
  }
}

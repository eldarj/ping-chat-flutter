import 'dart:async';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:http/http.dart';
import 'package:tus_client/tus_client.dart';

const String API_BASE_URL = 'http://192.168.1.4:8089';
const String DATA_SPACE_ENDPOINT = '/api/data-space/upload';

class HttpClientService {
  static Map<String, Response> cache = {};

  static Future<http.Response> post(url, {body = const {}, headers = const {}, bool encode = true, String token}) async {
    if (token == null) {
      token = await UserService.getToken();
    }

    var response = await http.post(
        Uri.encodeFull(API_BASE_URL + url),
        headers: {'content-type': 'application/json', 'authorization': 'Bearer $token',...headers},
        body: encode ? json.encode(body) : body
    ).timeout(Duration(seconds: 10));

    return response;
  }

  static Future<http.Response> get(url, { cacheKey }) async {
    if (cacheKey != null && cache.containsKey(cacheKey)) {
      return cache[cacheKey];
    }

    var userToken = await UserService.getToken();

    var response = await http.get(
        Uri.encodeFull(API_BASE_URL + url),
        headers: {'content-type': 'application/json', 'authorization': 'Bearer $userToken'}
    ).timeout(Duration(seconds: 10));

    if (cacheKey != null) {
      cache[cacheKey] = response;
    }

    return response;
  }

  static Future<http.Response> getQuery(endpoint, queryMap) async {
    var userToken = await UserService.getToken();

    var response = await http.get(
        Uri.http('192.168.1.4:8089', endpoint, queryMap),
        headers: {'content-type': 'application/json', 'authorization': 'Bearer $userToken'}
    ).timeout(Duration(seconds: 10));

    return response;
  }

  static Future<http.StreamedResponse> postMultipartFile(String url, String filename, File file,
      {String multipartFieldName: 'file'}) async
  {
    var userToken = await UserService.getToken();
    var headers = { 'authorization': 'Bearer $userToken' };

    var request = http.MultipartRequest('POST', Uri.parse(API_BASE_URL + url));
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

  static delete(String url) async {
    var userToken = await UserService.getToken();

    var response = await http.delete(
      Uri.encodeFull(API_BASE_URL + url),
      headers: {'authorization': 'Bearer $userToken'},
    ).timeout(Duration(seconds: 10));

    return response;
  }

  // TODO: Remove - unused
  static void postStream(String url, String filename, File file) async {
    var userToken = await UserService.getToken();
    var fileLength = await file.length();

    final streamedRequest = new http.StreamedRequest('POST', Uri.http('192.168.1.4:8089', url))
      ..headers.addAll({
        'Authorization': 'Bearer $userToken',
      });

    streamedRequest.contentLength = fileLength;

    var totalChunkSize = 0;
    file.openRead().listen((chunk) {
      streamedRequest.sink.add(chunk);
      totalChunkSize += chunk.length;
      print(chunk.length);
    }, onDone: () {
      streamedRequest.sink.close();
      print("${(totalChunkSize / 1000).floor() / 1000}MB - streams from initial content length "
          "${(streamedRequest.contentLength / 1000).floor() / 1000}MB");
    }, onError: (e) {
      print(e);
    });
  }
}

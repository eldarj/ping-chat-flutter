import 'dart:async';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:http/http.dart';
import 'package:tus_client/tus_client.dart';

class HttpClientService {
  static const String _API_BASE_URL = 'http://192.168.1.4:8089';

  static const String _DATA_SPACE_ENDPOINT = '/api/data-space/upload';

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

  static Future<http.Response> getQuery(endpoint, queryMap) async {
    var userToken = await UserService.getToken();

    var response = await http.get(
        Uri.http('192.168.1.4:8089', endpoint, queryMap),
        headers: {'content-type': 'application/json', 'authorization': 'Bearer $userToken'}
    ).timeout(Duration(seconds: 10));

    return response;
  }

  static getFileUlr(String fileName) {
    return Uri.parse(_API_BASE_URL + _DATA_SPACE_ENDPOINT + '/' + fileName);
  }

  static tusUpload(file, {
    startF,
    Function(dynamic) completeF,
    Function(double) progressF,
    Function(dynamic) errF
  }) async {

    var userToken = await UserService.getToken();

    TusClient tusClient = TusClient(
      Uri.parse(_API_BASE_URL + _DATA_SPACE_ENDPOINT),
      file,
      store: TusMemoryStore(),
      headers: {'Authorization': 'Bearer $userToken'},
    );

    try {
      await tusClient.upload(
        onComplete: (response) async {
          if (completeF != null)
            completeF(response);
        },
        onProgress: (progress) {
          if (progressF != null)
            progressF(progress);
        },
      );

      if (startF != null)
        startF();
    } catch (exception) {
      if (errF != null)
        errF(exception);
    }
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

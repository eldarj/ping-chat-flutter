import 'dart:convert';

import 'package:http/http.dart' as http;

extension HttpResponseDecodingExtension on http.Response {
  dynamic decode() {
    return json.decode(utf8.decode(this.bodyBytes));
  }
}

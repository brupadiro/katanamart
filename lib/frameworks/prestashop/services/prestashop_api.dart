import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../common/constants.dart';
import '../../../common/tools/parse_xml.dart';

class PrestashopAPI {
  late final String url;
  late final String key;
  final storage = FlutterSecureStorage();
  ParseXml xml = ParseXml();
  PrestashopAPI({required this.url, required this.key});

  String apiLink(String endPoint) {
    if (endPoint.contains('?')) {
      return '$url/$endPoint&output_format=JSON&display=full';
    } else {
      return '$url/$endPoint?output_format=JSON&display=full';
    }
  }

  String loginLink(String endPoint) {
    print(url);
    return '$url/$endPoint&output_format=JSON&display=full';
  }

  Future<dynamic> getAsync(String endPoint) async {
    var response = await httpGet(Uri.tryParse(apiLink(endPoint))!,
        headers: <String, String>{
          // FIXME
          'Authorization': 'Basic ' + base64Encode(utf8.encode('$key:')),
        });

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> postAsync(
      String endPoint, Map<String, dynamic> body, String parent) async {
    print("================================");
    print(xml.mapToXml(body, parent));
    print("================================");
    var response = await httpPost(
      Uri.tryParse(apiLink(endPoint))!,
      headers: <String, String>{
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$key:')),
      },
      body: xml.mapToXml(body, parent),
    );
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> signin(String endPoint, Map<String, dynamic> body) async {
    var response = await httpGet(
      Uri.tryParse(loginLink('$endPoint?email=${body['email']}'))!,
      headers: <String, String>{
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$key:')),
      },
    );
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

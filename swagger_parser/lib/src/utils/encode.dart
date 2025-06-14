import 'dart:convert';

String encode(String value) {
  return base64Encode(utf8.encode(value)).replaceAll('=', '');
}

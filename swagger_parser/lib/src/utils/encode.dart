import 'dart:convert';

String encode(String value) {
  return utf8.decode(base64.decode(value)).replaceAll('=', '');
}

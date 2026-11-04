import 'dart:io';
import 'dart:convert';
import 'package:encrypt/encrypt.dart';

void main() {
  final key = Key.fromUtf8('IZIVPN_AES_KEY_32BYTES_PROD_2026');
  final iv = IV.fromUtf8('IZIVPN_IV_16BYTE');

  final rawFile = File('servers_raw.json');
  if (!rawFile.existsSync()) {
    print('Error: servers_raw.json not found in current directory.');
    exit(1);
  }

  final rawJson = rawFile.readAsStringSync();
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  final encrypted = encrypter.encrypt(rawJson, iv: iv);

  final outputFile = File('servers.json');
  outputFile.writeAsStringSync(encrypted.base64);

  print('✅ Successfully encrypted servers_raw.json -> servers.json (${encrypted.base64.length} bytes)');
}

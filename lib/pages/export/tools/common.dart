import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeneralResult<T> {
  final int errno;
  final String message;
  final int elapsedTime;
  final T? data;

  GeneralResult({
    required this.errno,
    required this.message,
    required this.elapsedTime,
    this.data,
  });

  factory GeneralResult.fromMap(Map<String, dynamic> map) {
    return GeneralResult(
      errno: map['errno'],
      message: map['message'],
      elapsedTime: map['elapsedTime'],
      data: map['data'],
    );
  }
}

String generateSecureRandomKey(int length) {
  final Random secureRandom = Random.secure();
  final Uint8List randomBytes = Uint8List(length);

  for (int i = 0; i < length; i++) {
    randomBytes[i] = secureRandom.nextInt(256);
  }

  return base64UrlEncode(randomBytes); // 或者使用 hex.encode(randomBytes) 生成十六进制
}

// 生成随机密钥 (这里用简单的字符串替代真实的随机生成方式)
String generateRandomKey() {
  return generateSecureRandomKey(32); // 32 字节长度（256-bit 密钥）
}

// 从 secure storage 获取数据库加密密钥，如果不存在则生成并存储
Future<String> getOrCreateEncryptionKey() async {
  const FlutterSecureStorage secureStorage =
      FlutterSecureStorage(); // Secure storage instance
  String? encryptionKey = await secureStorage.read(key: 'db_encryption_key');
  if (encryptionKey == null) {
    // 如果没有密钥，生成一个随机的密钥并存储到 secure storage
    encryptionKey = generateRandomKey();
    await secureStorage.write(key: 'db_encryption_key', value: encryptionKey);
  }
  return encryptionKey;
}

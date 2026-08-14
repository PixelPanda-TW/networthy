import 'dart:convert';

class DatabaseKey {
  DatabaseKey.fromBytes(List<int> bytes)
    : bytes = List<int>.unmodifiable(bytes) {
    if (bytes.length != byteLength) {
      throw ArgumentError.value(
        bytes.length,
        'bytes.length',
        'Database keys must be exactly 256 bits.',
      );
    }
  }

  static const int byteLength = 32;

  final List<int> bytes;

  String encodeForStorage() {
    return base64UrlEncode(bytes);
  }

  String hexForSqlitePragma() {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static DatabaseKey decodeFromStorage(String encoded) {
    return DatabaseKey.fromBytes(base64Url.decode(encoded));
  }
}

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility functions for stable JSON serialization and validation.
/// Used by persistence and teacher dashboard services to ensure
/// consistent data serialization and integrity.
class JsonUtils {
  JsonUtils._();

  /// Convert a map to stable JSON string with sorted keys.
  /// This ensures consistent serialization regardless of insertion order.
  static String toStableJson(Map<String, dynamic> json) {
    final stable = _toStableJsonValue(json);
    return jsonEncode(stable);
  }

  /// Recursively make all values stable for JSON encoding.
  static dynamic _toStableJsonValue(dynamic value) {
    if (value is Map) {
      final keys = value.keys.toList()
        ..sort((a, b) => a.toString().compareTo(b.toString()));
      final sortedMap = <String, dynamic>{};
      for (final key in keys) {
        sortedMap[key.toString()] = _toStableJsonValue(value[key]);
      }
      return sortedMap;
    }

    if (value is List) {
      return value.map(_toStableJsonValue).toList();
    }

    return value;
  }

  /// Calculate SHA256 checksum of data.
  static String calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

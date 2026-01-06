import 'dart:convert';

class JwtUtils {
  const JwtUtils._();

  static Map<String, dynamic> decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      throw const FormatException('Invalid JWT');
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final jsonMap = json.decode(decoded);
    if (jsonMap is! Map<String, dynamic>) {
      throw const FormatException('Invalid JWT payload');
    }
    return jsonMap;
  }

  static String? tryGetRole(String token) {
    try {
      final payload = decodePayload(token);
      final role = payload['role'];
      return role is String ? role : null;
    } catch (_) {
      return null;
    }
  }

  static String? tryGetUserId(String token) {
    try {
      final payload = decodePayload(token);
      final userId = payload['userId'];
      return userId is String ? userId : null;
    } catch (_) {
      return null;
    }
  }
}
